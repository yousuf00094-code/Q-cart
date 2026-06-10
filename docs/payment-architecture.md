# Q Cart – Payment Architecture

**Market:** State of Qatar  
**Regulatory authority:** Qatar Central Bank (QCB)  
**Settlement currency:** Qatari Riyal (QAR)  
**PCI DSS scope:** Level 1 (target) — card data never touches Q Cart servers

---

## 1. Architecture Overview

```
Customer Device
      │
      ▼
┌─────────────────────────────────────────────────────┐
│                  Q Cart API  (Node.js)               │
│                                                     │
│  POST /v1/orders/checkout                           │
│        │                                            │
│        ▼                                            │
│  PaymentService  ──────► PaymentRouter              │
│                               │                    │
│              ┌────────────────┼──────────────┐      │
│              ▼                ▼              ▼      │
│         QPay/NAPS         Stripe         COD Flow   │
│       (Visa/MC/          (Apple Pay /               │
│        Debit)            Google Pay /               │
│                          Visa/MC intl)              │
└─────────────────────────────────────────────────────┘
         │                    │
         ▼                    ▼
   QCB Payment          Stripe Gateway
   Infrastructure        (PCI DSS L1)
```

**Core principle:** Q Cart is a payment *orchestrator*, not a processor. Raw card PANs are never received, stored, or logged. All sensitive card data is tokenised at the client by the payment SDK before the API is called.

---

## 2. Payment Methods

### 2.1 QPay (Primary — Qatar Local)

QPay is the national payment network operated by Qatar Central Bank. It is the **preferred integration** for Qatar-resident cardholders and is mandatory for government compliance.

**How it works:**
1. Checkout screen renders QPay button via QPay JS/Mobile SDK.
2. Customer authenticates via their bank's QPay-enrolled credentials or QR code.
3. QPay returns a `transaction_token` to the client.
4. Client sends `transaction_token` to `POST /v1/orders/checkout`.
5. Q Cart backend calls QPay server-to-server to settle the charge.
6. QPay responds with `CAPTURED` or `FAILED`.

**Supported card schemes via QPay:** Visa, Mastercard, NAPS (National ATM & POS Switch) debit cards

**Endpoint:** `https://api.qpay.gov.qa/v2/` (sandbox: `https://api-sandbox.qpay.gov.qa/v2/`)

**Backend flow:**
```
POST /qpay/v2/payment/initiate
  {
    "merchant_id":    "<QPAY_MERCHANT_ID>",
    "amount":         "183.50",
    "currency":       "QAR",
    "transaction_ref": "<order_uuid>",
    "token":          "<client_transaction_token>",
    "callback_url":   "https://api.qcart.qa/v1/webhooks/qpay"
  }
```

**Webhook verification:** HMAC-SHA256 over `merchant_id + amount + transaction_ref` using the shared secret.

---

### 2.2 Visa (International)

Processed via **Stripe** with 3-D Secure 2 (3DS2) challenge flow.

**Client flow:**
1. Stripe.js / Stripe React Native SDK collects PAN, expiry, CVV directly inside a Stripe-hosted iframe/element — **card data never enters Q Cart's DOM or network**.
2. Stripe returns a `PaymentMethod` ID (`pm_xxxx`).
3. Client passes `pm_xxxx` to `POST /v1/orders/checkout` as `payment_token`.
4. Q Cart backend calls `stripe.paymentIntents.create({ amount, currency: 'qar', payment_method })`.
5. If 3DS2 challenge required, Stripe returns `requires_action` with a `next_action.redirect_to_url`.
6. Client completes challenge; Stripe calls Q Cart webhook on success.

**3DS2 handling:**
```
stripe.confirmPayment(clientSecret)
  → requires_action  → redirect to 3DS challenge page
  → succeeded        → poll GET /v1/orders/:id for confirmed status
```

**Supported Visa types:** Visa Credit, Visa Debit, Visa Prepaid, Qatar-issued Visa Electron.

---

### 2.3 Mastercard (International)

Same Stripe integration as Visa above. Additional Mastercard-specific flow: **Mastercard Identity Check** (rebranded 3DS2) is invoked automatically by Stripe for all Qatar-issued Mastercards. No extra integration work required beyond the Visa flow.

**Supported Mastercard types:** Mastercard Credit, Debit, Prepaid, World, World Elite.

---

### 2.4 Apple Pay

Apple Pay is supported on iOS 11+ and Safari macOS. Cards are stored in the Secure Element on-device; Q Cart never sees the actual card number — only an encrypted payment token.

**Prerequisites:**
- Apple Pay merchant certificate registered at developer.apple.com.
- Merchant domain verification file hosted at `https://qcart.qa/.well-known/apple-developer-merchantid-domain-association`.
- Stripe handles merchant certificate management via the Stripe Dashboard.

**Client flow (React Native / Flutter):**
```
1. Check availability: await Stripe.isApplePaySupported()
2. Present sheet:      await Stripe.presentApplePay({ cartItems, country: 'QA', currency: 'QAR' })
3. On confirm:         confirmApplePayPayment(clientSecret)
4. Complete:           Stripe.completeApplePay()
```

**What Q Cart backend does:**
1. `POST /v1/orders/checkout` receives `payment_method: 'apple_pay'` + `payment_token`.
2. Backend creates a Stripe PaymentIntent with `payment_method_types: ['card']` — Apple Pay tokens are standard card tokens under the hood.
3. Confirm intent server-side; no 3DS required (Apple Pay provides its own biometric auth).

**Support:** iPhone 6+, Apple Watch, iPad, MacBook Pro with Touch ID, Safari 11+ on macOS.

---

### 2.5 Google Pay

Google Pay is supported on Android 5.0+ (API 21+) with Chrome 61+ or Android WebView.

**Prerequisites:**
- Google Pay API merchant registration at `https://pay.google.com/business/console`.
- Set `environment: 'PRODUCTION'` after Google approval (use `'TEST'` during development).

**Client flow (Flutter / React Native):**
```
1. Check readiness:  await GooglePay.isReadyToPay()
2. Request payment:  await Stripe.initGooglePay({ testEnv: false, merchantName: 'Q Cart', countryCode: 'QA' })
3. Present sheet:    await Stripe.presentGooglePay({ clientSecret })
4. Status polling:   GET /v1/orders/:id
```

**What Q Cart backend does:**
Same as Apple Pay — Stripe normalises Google Pay tokens into standard card payment methods.

**Support:** Android 5.0+, Chrome browser (desktop + Android), Chrome WebView.

---

### 2.6 Cash on Delivery (COD)

Available for orders under **QAR 500** within Doha, Al Wakrah, Al Khor, and Al Rayyan. Not available for marketplace seller items or pre-order products.

**Flow:**
```
POST /v1/orders/checkout
  { payment_method: 'cash_on_delivery' }
  → Order created with payment_status: 'pending'
  → Delivery agent collects cash at door
  → Agent marks order paid in driver app
  → Webhook POST /v1/webhooks/delivery { event: 'payment_collected', order_id }
  → payment_status → 'paid'
```

**COD fee:** QAR 5 added to delivery_fee (configurable via `PAYMENT_COD_FEE` env var).

**COD validation rules (enforced in `order.service.js`):**
```javascript
const COD_MAX_AMOUNT  = 500;    // QAR
const COD_AREAS = ['doha', 'al_wakrah', 'al_khor', 'al_rayyan'];

if (paymentMethod === 'cash_on_delivery') {
  if (total > COD_MAX_AMOUNT) throw new AppError('COD not available for orders over QAR 500', 422);
  if (!COD_AREAS.includes(deliveryArea)) throw new AppError('COD not available in this area', 422);
}
```

---

## 3. Backend Service Design

### 3.1 PaymentService (`src/services/payment.service.js`)

```javascript
class PaymentService {
  async initiatePayment({ orderId, amount, method, token, metadata }) { ... }
  async confirmPayment({ orderId, paymentIntentId }) { ... }
  async refund({ orderId, amount, reason }) { ... }
  async handleWebhook({ provider, payload, signature }) { ... }
}
```

### 3.2 Payment Router (strategy pattern)

```javascript
const PROCESSORS = {
  card:             StripeProcessor,
  apple_pay:        StripeProcessor,   // same processor, different token type
  google_pay:       StripeProcessor,
  cash_on_delivery: CodProcessor,
  qpay:             QPayProcessor,
};

const processor = PROCESSORS[method];
if (!processor) throw new AppError('Unsupported payment method', 422);
return processor.charge({ amount, token, metadata });
```

### 3.3 Idempotency

All payment API calls use idempotency keys to prevent double charges on network retries:

```javascript
// Stripe
stripe.paymentIntents.create({ ... }, {
  idempotencyKey: `order_${orderId}_attempt_${attemptNumber}`,
});

// QPay
headers['X-Idempotency-Key'] = `qcart_${orderId}`;
```

### 3.4 Webhook Endpoints

| Provider | Endpoint | Verification |
|---|---|---|
| Stripe | `POST /v1/webhooks/stripe` | `stripe.webhooks.constructEvent(body, sig, secret)` |
| QPay | `POST /v1/webhooks/qpay` | HMAC-SHA256 header `X-QPay-Signature` |
| Delivery COD | `POST /v1/webhooks/delivery` | Shared bearer token |

**Webhook events handled:**

```
Stripe:
  payment_intent.succeeded     → order.payment_status = 'paid', status = 'confirmed'
  payment_intent.payment_failed → order.payment_status = 'failed', notify customer
  charge.refunded              → order.payment_status = 'refunded', status = 'refunded'

QPay:
  PAYMENT_CAPTURED             → order.payment_status = 'paid'
  PAYMENT_FAILED               → order.payment_status = 'failed'
  PAYMENT_REFUNDED             → order.payment_status = 'refunded'
```

---

## 4. Database Schema (additions to schema.sql)

```sql
CREATE TABLE payment_attempts (
  id                UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id          UUID        NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  provider          VARCHAR(30) NOT NULL,   -- 'stripe', 'qpay', 'cod'
  provider_ref      VARCHAR(255),           -- stripe PaymentIntent ID / QPay txn ref
  amount            NUMERIC(10,2) NOT NULL,
  currency          CHAR(3)     NOT NULL DEFAULT 'QAR',
  status            VARCHAR(30) NOT NULL DEFAULT 'initiated',
  failure_code      VARCHAR(100),
  failure_message   TEXT,
  idempotency_key   VARCHAR(255) UNIQUE,
  raw_response      JSONB,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payment_order    ON payment_attempts (order_id);
CREATE INDEX idx_payment_provider ON payment_attempts (provider, provider_ref);
CREATE INDEX idx_payment_status   ON payment_attempts (status);
```

---

## 5. Refunds

| Scenario | Timeline | Process |
|---|---|---|
| Cancelled before dispatch | Instant | Stripe/QPay automatic reversal |
| Returned after delivery | 3–5 business days | Manual via admin dashboard |
| COD refund | Bank transfer within 7 days | Manual QNB/QIIB transfer |

**Partial refunds** are supported for multi-item orders where only some items are returned.

---

## 6. Security Controls

| Control | Implementation |
|---|---|
| PCI DSS scope reduction | Stripe.js / Apple Pay / Google Pay — raw PANs never touch Q Cart servers |
| TLS | TLS 1.2+ enforced on all payment endpoints; HSTS enabled |
| Webhook signature verification | Stripe `constructEvent`, QPay HMAC-SHA256 |
| Idempotency | Per-order idempotency keys on all charge requests |
| Rate limiting | `/v1/orders/checkout` limited to 5 req/min per user |
| Fraud signals | Stripe Radar rules: block non-QA IP for COD, velocity checks |
| Logs | `payment_reference` stored; raw card data never logged |
| Secret management | All API keys in environment variables, never in source code |

---

## 7. Environment Variables

```env
# Stripe
STRIPE_SECRET_KEY=sk_live_...
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# QPay
QPAY_MERCHANT_ID=QCART001
QPAY_SECRET=...
QPAY_BASE_URL=https://api.qpay.gov.qa/v2

# COD
PAYMENT_COD_FEE=5.00
PAYMENT_COD_MAX_AMOUNT=500.00
```

---

## 8. Testing

| Environment | Stripe key prefix | QPay environment |
|---|---|---|
| Development | `sk_test_...` | sandbox |
| Staging | `sk_test_...` | sandbox |
| Production | `sk_live_...` | production |

**Stripe test cards:**
| Scenario | Card number |
|---|---|
| Success | `4242 4242 4242 4242` |
| 3DS2 required | `4000 0027 6000 3184` |
| Insufficient funds | `4000 0000 0000 9995` |
| Declined | `4000 0000 0000 0002` |

---

## 9. Compliance

| Requirement | Status |
|---|---|
| QCB Electronic Payment Regulations (2021) | In scope — QPay integration required for QAR transactions |
| PCI DSS | Scope minimised via Stripe tokenisation; SAQ A eligible |
| 3DS2 (PSD2 equivalent) | Enforced via Stripe for all card payments |
| PDPA Qatar (Law No. 13 of 2016) | No card data stored; only `payment_reference` retained |
| VAT | Qatar introduced 5% VAT (Jan 2024); applied at checkout in totals |
