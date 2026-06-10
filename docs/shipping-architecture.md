# Q Cart – Shipping Architecture

**Market:** State of Qatar  
**Geography:** ~11,571 km² total area; majority of population in Doha metropolitan region  
**Currency:** Qatari Riyal (QAR)  
**Delivery zones:** 7 zones covering all inhabited areas of Qatar

---

## 1. Architecture Overview

```
Customer Places Order
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│                  Q Cart API  (Node.js)                   │
│                                                         │
│  POST /v1/orders/checkout                               │
│        │                                                │
│        ▼                                                │
│  ShippingService ──────► CarrierRouter                  │
│                               │                        │
│         ┌─────────────────────┼─────────────────┐       │
│         ▼                     ▼                 ▼       │
│   Q Cart Fleet          Aramex Qatar       DHL Express  │
│  (Same-Day / Express   (Standard /        (International│
│   within Doha metro)    Next-Day Qatar)    / Premium)   │
└─────────────────────────────────────────────────────────┘
         │                     │                 │
         ▼                     ▼                 ▼
  In-house Driver App    Aramex API          DHL API
  (real-time tracking)  (label + track)    (label + track)
```

**Core principle:** Q Cart selects the optimal carrier automatically based on delivery zone, service tier, item weight/dimensions, and order value. The customer sees a unified tracking experience regardless of carrier.

---

## 2. Delivery Zones

Qatar is divided into seven delivery zones aligned with municipality boundaries:

| Zone | Areas | Carriers Available | Est. Standard Delivery |
|------|--------|--------------------|------------------------|
| Z1 | Doha (central) | Q Cart Fleet, Aramex, DHL | Same-day / Next-day |
| Z2 | Al Rayyan | Q Cart Fleet, Aramex | Same-day / Next-day |
| Z3 | Al Wakrah | Q Cart Fleet, Aramex | Same-day / Next-day |
| Z4 | Al Khor, Al Thakhira | Aramex | 1–2 business days |
| Z5 | Mesaieed, Dukhan | Aramex | 1–2 business days |
| Z6 | Al Shamal, Madinat ash Shamal | Aramex | 2–3 business days |
| Z7 | Al Karaana, Umm Bab, Zekreet | Aramex | 2–3 business days |

> **Note:** COD (Cash on Delivery) is restricted to Zones Z1–Z3 only (Doha, Al Rayyan, Al Wakrah).

---

## 3. Service Tiers

### 3.1 Same-Day Delivery

- **Available:** Zones Z1, Z2, Z3 only
- **Cutoff time:** Orders placed before **2:00 PM AST (GMT+3)** qualify for same-day
- **Delivery window:** 4–8 PM same day
- **Fee:** QAR 25 flat
- **Carrier:** Q Cart Fleet (in-house)
- **Eligibility:** Orders under 10 kg, no hazardous items, items must be in-stock

### 3.2 Express Delivery (Next-Day)

- **Available:** Zones Z1–Z3 (next-day); Zones Z4–Z7 (2-day)
- **Cutoff time:** Orders placed before **6:00 PM AST**
- **Delivery window:** 9 AM–6 PM next business day
- **Fee:** QAR 15 flat
- **Carrier:** Q Cart Fleet (Z1–Z3), Aramex (Z4–Z7)
- **Eligibility:** Orders under 30 kg

### 3.3 Standard Delivery

- **Available:** All zones (Z1–Z7)
- **Timeline:** 2–3 business days
- **Fee:** QAR 10 flat (free for orders ≥ QAR 200)
- **Carrier:** Aramex Qatar
- **Free delivery threshold:** Configurable via `SHIPPING_FREE_THRESHOLD` env var (default: QAR 200)

### 3.4 Scheduled Delivery

- **Available:** Zones Z1–Z3
- **Timeline:** Customer selects a 2-hour window up to 7 days in advance
- **Fee:** QAR 20 flat
- **Carrier:** Q Cart Fleet
- **Slots:** 8 AM–10 AM, 10 AM–12 PM, 12 PM–2 PM, 2 PM–4 PM, 4 PM–6 PM, 6 PM–8 PM

### 3.5 International / Premium

- **Available:** For items sourced internationally or premium courier requests
- **Carrier:** DHL Express
- **Fee:** Calculated dynamically via DHL Rate API based on weight, dimensions, origin, destination
- **Timeline:** 1–5 business days depending on origin

---

## 4. Fee Calculation

```javascript
// src/services/shipping.service.js — calculateShippingFee()

const FREE_THRESHOLD = parseFloat(process.env.SHIPPING_FREE_THRESHOLD || '200');

const ZONE_TIER_FEES = {
  same_day:  { Z1: 25, Z2: 25, Z3: 25 },
  express:   { Z1: 15, Z2: 15, Z3: 15, Z4: 20, Z5: 20, Z6: 20, Z7: 20 },
  standard:  { Z1: 10, Z2: 10, Z3: 10, Z4: 10, Z5: 10, Z6: 10, Z7: 10 },
  scheduled: { Z1: 20, Z2: 20, Z3: 20 },
};

function calculateShippingFee({ zone, tier, orderSubtotal, weight }) {
  // Free shipping on standard tier above threshold
  if (tier === 'standard' && orderSubtotal >= FREE_THRESHOLD) return 0;

  // Overweight surcharge: +QAR 2 per kg above 5 kg (standard/express only)
  const base = ZONE_TIER_FEES[tier]?.[zone];
  if (!base) throw new AppError('Service not available in this zone', 422);

  let fee = base;
  if (['standard', 'express'].includes(tier) && weight > 5) {
    fee += Math.ceil(weight - 5) * 2;
  }

  return fee;
}
```

---

## 5. Carrier Integrations

### 5.1 Q Cart Fleet (In-House)

Q Cart maintains a fleet of delivery drivers for same-day and express deliveries in the Doha metro area. Drivers use the Q Cart Driver App (Flutter mobile).

**Dispatch flow:**
```
Order confirmed
      │
      ▼
ShippingService.assignDriver(orderId)
      │
      ▼
Find nearest available driver (PostGIS ST_DWithin on driver GPS location)
      │
      ▼
Push notification to driver app via FCM
      │
      ▼
Driver accepts → status = 'driver_assigned'
Driver picks up → status = 'out_for_delivery'
Driver delivers → status = 'delivered' + photo proof + recipient name
      │
      ▼
POST /v1/webhooks/delivery { event: 'delivered', order_id, proof_photo_url }
```

**Driver location updates:** Driver app sends GPS coordinates to `PATCH /v1/driver/location` every 30 seconds while on active delivery. Customers can poll `GET /v1/orders/:id/tracking` for live coordinates.

### 5.2 Aramex Qatar

Aramex is Q Cart's primary third-party carrier for zones Z4–Z7 and overflow capacity in Z1–Z3.

**Credentials:**
```env
ARAMEX_ACCOUNT_NUMBER=...
ARAMEX_USERNAME=...
ARAMEX_PASSWORD=...
ARAMEX_ENTITY_CODE=AMM
ARAMEX_BASE_URL=https://ws.aramex.net/ShippingAPI.V2/
```

**Shipment creation:**
```javascript
POST https://ws.aramex.net/ShippingAPI.V2/Shipping/Service_1_0.svc/json/CreateShipments
{
  "Shipments": [{
    "Shipper": {
      "Reference1": "<order_uuid>",
      "AccountNumber": "<ARAMEX_ACCOUNT_NUMBER>",
      "PartyAddress": {
        "Line1": "Q Cart Warehouse, Industrial Area",
        "City": "Doha", "CountryCode": "QA"
      }
    },
    "Consignee": {
      "PartyAddress": { /* customer address */ },
      "PhoneNumber1": "<customer_phone>"
    },
    "Details": {
      "PaymentType": "P",   // prepaid
      "ProductGroup": "EXP", // express
      "ProductType": "PPX",
      "ActualWeight": { "Value": 2.5, "Unit": "KG" },
      "NumberOfPieces": 1,
      "CashOnDeliveryAmount": { "Value": 0, "CurrencyCode": "QAR" }
    }
  }]
}
```

**Response:** `Shipments[0].ID` → stored as `shipments.carrier_tracking_id`.

**Tracking webhooks:** Aramex calls `POST /v1/webhooks/aramex` on status updates. Q Cart maps Aramex event codes to internal statuses:

| Aramex Event | Q Cart Status |
|---|---|
| `SH004` (Picked Up) | `picked_up` |
| `SH010` (In Transit) | `in_transit` |
| `SH016` (Out for Delivery) | `out_for_delivery` |
| `SH020` (Delivered) | `delivered` |
| `SH030` (Delivery Attempt Failed) | `delivery_attempted` |
| `SH040` (Returned to Sender) | `returned` |

### 5.3 DHL Express Qatar

Used for international shipments and premium express domestic deliveries.

**Credentials:**
```env
DHL_ACCOUNT_NUMBER=...
DHL_API_KEY=...
DHL_BASE_URL=https://express.api.dhl.com/mydhlapi
```

**Rate query:**
```javascript
GET /mydhlapi/rates?accountNumber=<DHL_ACCOUNT_NUMBER>
  &originCountryCode=QA&originCityName=Doha
  &destinationCountryCode=QA&destinationCityName=<city>
  &weight=<kg>&length=<cm>&width=<cm>&height=<cm>
  &plannedShippingDateAndTime=<ISO8601>
  &isCustomsDeclarable=false
```

**Label creation:**
```javascript
POST /mydhlapi/shipments
{
  "plannedShippingDateAndTime": "<ISO8601>",
  "pickup": { "isRequested": false },
  "productCode": "N",   // domestic express
  "accounts": [{ "typeCode": "shipper", "number": "<DHL_ACCOUNT_NUMBER>" }],
  "customerReferences": [{ "value": "<order_uuid>", "typeCode": "CU" }],
  "outputImageProperties": { "encodingFormat": "pdf", "imageOptions": [{ "typeCode": "label" }] },
  "shipper": { /* Q Cart warehouse */ },
  "consignee": { /* customer */ },
  "packages": [{ "weight": 2.5, "dimensions": { "length": 30, "width": 20, "height": 15 } }]
}
```

---

## 6. Tracking

### 6.1 Unified Tracking Model

Regardless of carrier, customers see a single consistent timeline:

```
Order Confirmed → Preparing → Picked Up → In Transit → Out for Delivery → Delivered
```

Internal status machine:
```
pending → confirmed → processing → picked_up → in_transit
        → out_for_delivery → delivered
        → delivery_attempted → (retry) → delivered | returned
        → cancelled
```

### 6.2 Tracking API

```
GET /v1/orders/:id/tracking
Authorization: Bearer <token>

Response:
{
  "order_id": "uuid",
  "carrier": "aramex",
  "carrier_tracking_id": "1234567890",
  "status": "out_for_delivery",
  "eta": "2024-03-15T18:00:00+03:00",
  "driver_location": null,            // only for Q Cart Fleet
  "events": [
    { "status": "confirmed",          "timestamp": "...", "description": "Order confirmed" },
    { "status": "processing",         "timestamp": "...", "description": "Preparing your order" },
    { "status": "picked_up",          "timestamp": "...", "description": "Picked up by Aramex" },
    { "status": "out_for_delivery",   "timestamp": "...", "description": "On the way to you" }
  ]
}
```

For Q Cart Fleet orders, `driver_location` returns `{ lat, lng, updated_at }` refreshed every 30 seconds.

---

## 7. Database Schema

```sql
-- Delivery zones
CREATE TABLE delivery_zones (
  id          SERIAL      PRIMARY KEY,
  code        VARCHAR(5)  NOT NULL UNIQUE,  -- 'Z1' .. 'Z7'
  name        VARCHAR(100) NOT NULL,
  areas       TEXT[]      NOT NULL,         -- municipality/neighbourhood names
  is_active   BOOLEAN     NOT NULL DEFAULT TRUE
);

-- Shipping methods offered per zone
CREATE TABLE shipping_methods (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  zone_id       INT         NOT NULL REFERENCES delivery_zones(id),
  tier          VARCHAR(30) NOT NULL,  -- 'same_day','express','standard','scheduled'
  carrier       VARCHAR(30) NOT NULL,  -- 'fleet','aramex','dhl'
  base_fee      NUMERIC(8,2) NOT NULL,
  overweight_fee_per_kg NUMERIC(8,2) NOT NULL DEFAULT 0,
  cutoff_time   TIME,
  is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
  UNIQUE (zone_id, tier)
);

-- One shipment record per order
CREATE TABLE shipments (
  id                  UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id            UUID        NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  carrier             VARCHAR(30) NOT NULL,
  carrier_tracking_id VARCHAR(255),
  label_url           TEXT,
  tier                VARCHAR(30) NOT NULL,
  zone_code           VARCHAR(5)  NOT NULL,
  status              VARCHAR(30) NOT NULL DEFAULT 'pending',
  scheduled_window_start TIMESTAMPTZ,
  scheduled_window_end   TIMESTAMPTZ,
  shipped_at          TIMESTAMPTZ,
  delivered_at        TIMESTAMPTZ,
  delivery_attempts   INT         NOT NULL DEFAULT 0,
  proof_photo_url     TEXT,
  recipient_name      VARCHAR(255),
  driver_id           UUID        REFERENCES users(id),
  raw_carrier_response JSONB,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Append-only tracking event log
CREATE TABLE shipment_events (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  shipment_id UUID        NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
  status      VARCHAR(30) NOT NULL,
  description TEXT,
  carrier_event_code VARCHAR(20),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Driver GPS (latest position only — upserted by driver app)
CREATE TABLE driver_locations (
  driver_id   UUID        PRIMARY KEY REFERENCES users(id),
  lat         DOUBLE PRECISION NOT NULL,
  lng         DOUBLE PRECISION NOT NULL,
  accuracy    REAL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_shipment_order   ON shipments (order_id);
CREATE INDEX idx_shipment_carrier ON shipments (carrier, carrier_tracking_id);
CREATE INDEX idx_shipment_status  ON shipments (status);
CREATE INDEX idx_shipment_events  ON shipment_events (shipment_id, occurred_at DESC);
CREATE INDEX idx_shipment_driver  ON shipments (driver_id) WHERE driver_id IS NOT NULL;
```

---

## 8. Backend Service Design

### 8.1 ShippingService (`src/services/shipping.service.js`)

```javascript
class ShippingService {
  async getAvailableMethods({ addressId, items })     { ... }  // returns tiers + fees
  async calculateFee({ zone, tier, subtotal, weight }) { ... }
  async createShipment({ orderId, tier, carrier })    { ... }  // calls carrier API + stores record
  async updateTracking({ carrier, payload })          { ... }  // called from webhooks
  async assignDriver(orderId)                         { ... }  // Q Cart Fleet dispatch
  async getTracking(orderId)                          { ... }  // unified tracking response
}
```

### 8.2 Carrier Router (strategy pattern)

```javascript
const CARRIERS = {
  fleet:  FleetCarrier,
  aramex: AramexCarrier,
  dhl:    DhlCarrier,
};

// Zone → tier → carrier mapping
const ZONE_CARRIER_MAP = {
  Z1: { same_day: 'fleet', express: 'fleet',  standard: 'aramex', scheduled: 'fleet' },
  Z2: { same_day: 'fleet', express: 'fleet',  standard: 'aramex', scheduled: 'fleet' },
  Z3: { same_day: 'fleet', express: 'fleet',  standard: 'aramex', scheduled: 'fleet' },
  Z4: {                    express: 'aramex', standard: 'aramex' },
  Z5: {                    express: 'aramex', standard: 'aramex' },
  Z6: {                                       standard: 'aramex' },
  Z7: {                                       standard: 'aramex' },
};
```

### 8.3 Webhook Endpoints

| Carrier | Endpoint | Verification |
|---|---|---|
| Q Cart Fleet (driver app) | `POST /v1/webhooks/delivery` | Shared Bearer token |
| Aramex | `POST /v1/webhooks/aramex` | HMAC-SHA256 `X-Aramex-Signature` |
| DHL | `POST /v1/webhooks/dhl` | DHL API key header `DHL-API-Key` |

---

## 9. Scheduled Delivery Slot Management

```
GET /v1/shipping/slots?date=2024-03-15&zone=Z1
→ [
    { "slot_id": "2024-03-15_08-10", "window": "08:00–10:00", "available": true  },
    { "slot_id": "2024-03-15_10-12", "window": "10:00–12:00", "available": true  },
    { "slot_id": "2024-03-15_12-14", "window": "12:00–14:00", "available": false },
    ...
  ]
```

Slot capacity is governed by `FLEET_SLOT_CAPACITY` env var (default: 20 deliveries per slot per zone). A slot is marked unavailable when bookings reach capacity or the cutoff for same-day has passed.

---

## 10. Returns & Reverse Logistics

| Scenario | Process | Timeline |
|---|---|---|
| Defective / wrong item | Customer requests via app → Q Cart Fleet pickup scheduled | 1–2 business days |
| Change of mind | Customer requests within 24 h of delivery → standard return | 2–3 business days |
| Courier returns (failed delivery) | Aramex returns to Q Cart warehouse after 2 failed attempts | Automatic |
| Marketplace seller return | Routed back to supplier warehouse via Aramex | 3–5 business days |

**Return flow:**
```
POST /v1/orders/:id/returns
  { items: [{ product_id, quantity, reason }] }
  → Return request created (status: 'pending_pickup')
  → ShippingService.scheduleReturn(orderId)
  → Carrier pickup label generated
  → Status progresses: pending_pickup → picked_up → received → refund_initiated
```

---

## 11. Security Controls

| Control | Implementation |
|---|---|
| Webhook signature verification | HMAC-SHA256 for Aramex; Bearer token for Fleet driver app |
| Driver authentication | JWT with `role: 'driver'`; location updates only accepted from authenticated drivers |
| Address validation | Addresses geocoded against Qatar Post zone codes; invalid addresses rejected at checkout |
| Proof of delivery | Photo URL stored in `shipments.proof_photo_url`; accessible only to order owner + admin |
| Rate limiting | `/v1/shipping/slots` limited to 20 req/min per user |
| Carrier credential rotation | API keys in environment variables, never in source code |

---

## 12. Environment Variables

```env
# Q Cart Fleet
FLEET_SLOT_CAPACITY=20
FLEET_DISPATCH_RADIUS_KM=30

# Aramex
ARAMEX_ACCOUNT_NUMBER=...
ARAMEX_USERNAME=...
ARAMEX_PASSWORD=...
ARAMEX_ENTITY_CODE=AMM
ARAMEX_BASE_URL=https://ws.aramex.net/ShippingAPI.V2/

# DHL
DHL_ACCOUNT_NUMBER=...
DHL_API_KEY=...
DHL_BASE_URL=https://express.api.dhl.com/mydhlapi

# Shipping Config
SHIPPING_FREE_THRESHOLD=200.00
SHIPPING_SAME_DAY_CUTOFF=14:00
SHIPPING_EXPRESS_CUTOFF=18:00
```

---

## 13. Testing

| Scenario | Method |
|---|---|
| Zone detection | Unit test: supply address → assert zone code |
| Fee calculation | Unit tests for each tier × zone, overweight surcharge, free threshold |
| Aramex mock | Jest mock for `AramexCarrier.createShipment`; fixture JSON for webhook events |
| DHL mock | Jest mock for `DhlCarrier.getRates` and `DhlCarrier.createShipment` |
| Fleet dispatch | Integration test with in-memory driver pool |
| Webhook verification | Test valid + tampered HMAC; assert 401 on tampered signature |
| Slot availability | Unit test capacity limits and cutoff time enforcement |

---

## 14. Operations & SLAs

| Metric | Target |
|---|---|
| Same-Day on-time rate | ≥ 95% of orders placed before 2 PM delivered same day |
| Express on-time rate | ≥ 98% next-business-day delivery |
| Standard on-time rate | ≥ 99% within 3 business days |
| Delivery attempt success | ≥ 90% first-attempt delivery success |
| Tracking update latency | ≤ 60 seconds from carrier event to customer-visible update |
| Return pickup scheduling | Within 48 hours of return request approval |
