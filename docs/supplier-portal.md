# Q Cart – Supplier Portal

**Market:** State of Qatar  
**Portal type:** Multi-tenant supplier self-service + admin oversight  
**Authentication:** JWT (separate token namespace from customer app — `role: 'supplier'`)

---

## 1. Architecture Overview

```
Supplier Device (Flutter App / Web)
        │
        ▼
┌────────────────────────────────────────────────────────┐
│                   Q Cart API (Node.js)                  │
│                                                        │
│  /v1/suppliers/…          /v1/admin/suppliers/…        │
│       │                          │                     │
│       ▼                          ▼                     │
│  SupplierService          AdminSupplierService          │
│       │                          │                     │
│       └──────────────────────────┘                     │
│                    │                                   │
│            PostgreSQL + Redis                          │
└────────────────────────────────────────────────────────┘
```

**Roles involved:**
- `supplier` — Self-service portal (own data only)
- `admin` — Full oversight, approval/rejection, cross-supplier views

---

## 2. Supplier Portal Features

### 2.1 Supplier Login

Suppliers authenticate using business email and password. Access is granted only after admin approval of their application.

**Flow:**
```
POST /v1/auth/login  { email, password, context: 'supplier' }
→ Validates role === 'supplier'
→ Returns access_token (15 min) + sets refresh_token cookie (7 days)
→ Supplier Dashboard loaded
```

**Apply to Become a Supplier:**
```
POST /v1/suppliers/apply
  {
    "company_name":   "TechStore Qatar",
    "contact_name":   "Mohammed Al-Rashid",
    "email":          "tech@techstoreqa.com",
    "phone":          "+974 5512 3456",
    "category":       "Electronics",
    "cr_number":      "45678901",
    "documents":      ["cr_certificate_url", "tax_reg_url"]
  }
→ Creates supplier record with status: 'pending'
→ Admin notified for review
```

---

### 2.2 Supplier Dashboard

Overview screen showing key performance indicators for the current period.

**KPIs displayed:**
- Revenue (MTD) with trend percentage
- Total orders received
- Active product count
- Average customer rating

**Components:**
- Alert banner for inventory or compliance issues
- Quick-action grid (6 tiles)
- Recent orders list (last 5)
- Pending approval badge (products awaiting review)

**API:**
```
GET /v1/suppliers/me/dashboard
→ {
    revenue_mtd, revenue_change_pct,
    orders_mtd, active_products,
    avg_rating, low_stock_count,
    pending_product_approvals
  }
```

---

### 2.3 Product Submission

Suppliers submit products for admin review before they appear in the storefront.

**Submission fields:**
| Field | Required | Notes |
|-------|----------|-------|
| `name` | ✓ | |
| `sku` | — | Auto-generated if omitted |
| `category_id` | ✓ | Must be leaf category |
| `description` | ✓ | Min. 20 characters |
| `price` | ✓ | QAR, inclusive of 5% VAT |
| `compare_at_price` | — | Shown as strikethrough |
| `cost_price` | — | Visible only to supplier + admin |
| `images` | ✓ | Min. 1, max. 8 |
| `weight_kg` | — | Required if shipping via Aramex |
| `dimensions_cm` | — | L × W × H |
| `initial_stock` | ✓ | |
| `reorder_point` | — | Default: 5 |
| `tags` | — | Array of strings |

**Approval workflow states:**
```
draft → pending_review → approved → active
                       → rejected (with reason)
```

**API:**
```
POST /v1/suppliers/products
  { ...product fields }
  → status: 'pending_review', notifies admin

GET /v1/suppliers/products
  → paginated list of own products with approval status

PUT /v1/suppliers/products/:id
  → allowed on 'draft' or 'rejected' products only
  → re-submits to 'pending_review'
```

---

### 2.4 Product Approval Workflow

When a product is submitted, an admin reviews it before it becomes searchable.

**Admin review checklist:**
- Product name/description meets Q Cart guidelines
- Category correctly assigned
- Price within category norms
- Images meet quality standards (min. 400×400 px, no watermarks)
- No prohibited/restricted items (per QCB/MOCI regulations)

**Webhook to supplier on decision:**
```
POST <supplier_webhook_url>
  {
    "event": "product.approved" | "product.rejected",
    "product_id": "uuid",
    "reason": "string (rejection only)"
  }
```

**Admin API:**
```
GET  /v1/admin/suppliers/products?status=pending_review
POST /v1/admin/suppliers/products/:id/approve
POST /v1/admin/suppliers/products/:id/reject   { reason }
```

---

### 2.5 Inventory Updates

Suppliers manage stock levels for their products.

**Update types:**
| Type | Effect |
|------|--------|
| `restock` | Increases `quantity` |
| `adjustment` | Overrides `quantity` (with audit note) |
| `damage` | Reduces `quantity`, logs reason |
| `return` | Increases `quantity` from returned stock |

**API:**
```
GET  /v1/suppliers/inventory
  → [ { product_id, name, sku, quantity, reserved, reorder_point, status } ]

POST /v1/suppliers/inventory/adjust
  {
    "product_id":     "uuid",
    "transaction_type": "restock",
    "quantity_delta": 50,
    "notes":          "Supplier shipment INV-2024-006"
  }

POST /v1/suppliers/inventory/bulk
  { "updates": [{ product_id, quantity_delta, transaction_type }] }
```

**Alerts:** Suppliers receive push notifications when stock drops below `reorder_point`.

---

### 2.6 Purchase Orders

Q Cart issues Purchase Orders (POs) to suppliers when customer orders contain their products.

**PO lifecycle:**
```
new → accepted → processing → shipped → delivered
                            → delivery_failed → reshipped | returned
```

**Supplier actions:**
- **Accept** — confirms they can fulfil the order
- **Ship Now** — enters carrier + tracking number
- **Flag Issue** — notifies Q Cart ops of a problem

**API:**
```
GET /v1/suppliers/purchase-orders?status=new
GET /v1/suppliers/purchase-orders/:id

POST /v1/suppliers/purchase-orders/:id/accept
POST /v1/suppliers/purchase-orders/:id/ship
  { carrier, tracking_number, shipped_at }
POST /v1/suppliers/purchase-orders/:id/flag
  { reason, notes }
```

---

### 2.7 Shipment Tracking

Suppliers view outbound shipments and their current carrier status.

**Unified statuses:**
```
pending → picked_up → in_transit → out_for_delivery → delivered
                                                     → delivery_attempted
                                                     → returned
```

**API:**
```
GET /v1/suppliers/shipments
GET /v1/suppliers/shipments/:id/tracking
  → {
      shipment_id, carrier, tracking_number,
      status, destination, events: [{ status, timestamp, description }]
    }
```

---

### 2.8 Supplier Analytics

Revenue, order, and product performance reports available by period (week / month / quarter / year).

**Metrics available:**
| Metric | Description |
|--------|-------------|
| `gross_revenue` | Total sales before deductions |
| `net_payout` | After commission, VAT, returns |
| `orders_count` | Number of POs received |
| `units_sold` | Total SKU units sold |
| `return_rate` | Returns as % of orders |
| `avg_rating` | Aggregate customer rating |
| `top_products` | Ranked by revenue |
| `category_breakdown` | Revenue split by category |
| `funnel` | Views → Cart → Checkout → Ordered |
| `customer_ltv` | Average lifetime value of buyers |

**API:**
```
GET /v1/suppliers/analytics/overview?period=month
GET /v1/suppliers/analytics/products?period=month&limit=10
GET /v1/suppliers/analytics/customers?period=month
```

---

### 2.9 Supplier Ratings

Aggregate view of customer reviews across all products.

**Components:**
- Overall rating (1–5 ★) with distribution histogram
- Individual review list (filterable by star rating)
- Reply-to-review action (stored in `review_replies` table)
- Performance badges (Top Rated Seller / Fast Shipper / Responsive)
- Keyword sentiment cloud (positive vs. negative themes)
- Reply rate metric (target: ≥ 90%)

**API:**
```
GET  /v1/suppliers/reviews?rating=5&page=1
POST /v1/suppliers/reviews/:id/reply   { message }
GET  /v1/suppliers/reviews/summary
  → { avg_rating, total, breakdown: {5:n, 4:n, ...}, reply_rate, badges }
```

---

### 2.10 Supplier Payout Tracking

Suppliers track earnings, scheduled payouts, and bank account configuration.

**Payout schedule:** Twice monthly — 1st and 15th of each month.

**Deductions applied before payout:**
| Item | Rate |
|------|------|
| Q Cart Commission | 10% of gross sale |
| VAT collected (remitted to GTA) | 5% of gross sale |
| COD collection fee | QAR 5 per COD order |
| Return deduction | Full refund amount |
| Early payout fee (optional) | QAR 15 flat |

**API:**
```
GET  /v1/suppliers/payouts
GET  /v1/suppliers/payouts/balance
GET  /v1/suppliers/payouts/transactions?page=1
POST /v1/suppliers/payouts/request-early
  { amount }

GET  /v1/suppliers/bank-account
PUT  /v1/suppliers/bank-account
  { bank_name, iban, account_number, account_holder_name }
```

**Minimum payout threshold:** QAR 100 (configurable via `SUPPLIER_MIN_PAYOUT` env var).

---

## 3. Admin Features

### 3.1 Supplier Approval

Admins review and approve/reject supplier registration applications.

**Application review checklist:**
- Commercial Registration (CR) validity confirmed
- Tax Registration Number verified
- Bank account details provided
- Product category approved for Q Cart marketplace
- No sanctions or blacklist matches (Qatar Ministry of Commerce)

**API:**
```
GET  /v1/admin/suppliers?status=pending
GET  /v1/admin/suppliers/:id
POST /v1/admin/suppliers/:id/approve
POST /v1/admin/suppliers/:id/reject   { reason }
POST /v1/admin/suppliers/:id/suspend  { reason }
```

---

### 3.2 Supplier Performance Reports

Aggregate supplier performance across revenue, orders, ratings, shipping, and returns.

**Report dimensions:**
| Dimension | Metrics |
|-----------|---------|
| Revenue | GMV, net payout, commission earned |
| Fulfilment | On-time delivery %, fill rate %, cancelled POs % |
| Quality | Avg. rating, return rate %, defect rate % |
| Compliance | Reply rate %, late shipment rate % |

**Performance tiers:**
| Tier | Criteria |
|------|----------|
| ⭐ Top Seller | Rating ≥ 4.5, on-time ≥ 98%, return rate ≤ 2% |
| ✓ Good | Rating ≥ 4.0, on-time ≥ 95%, return rate ≤ 4% |
| ~ Average | Rating ≥ 3.5, on-time ≥ 90% |
| ⚠ At Risk | Rating < 3.5 or on-time < 85% or return rate > 7% |

**API:**
```
GET /v1/admin/suppliers/performance?period=month&sort=revenue
GET /v1/admin/suppliers/:id/performance?period=month
GET /v1/admin/suppliers/performance/export?period=month&format=csv
```

---

### 3.3 Supplier Risk Score

Automated risk scoring (0–100) calculated from performance signals. Higher score = higher risk.

**Risk factors and weights:**

| Factor | Weight | Trigger |
|--------|--------|---------|
| Return rate | 30 | > 5% = +30 pts |
| On-time delivery | 25 | < 90% = +25 pts |
| Rating trend | 20 | Declining over 3 months = +20 pts |
| Fill rate | 15 | < 85% = +15 pts |
| Late shipments | 10 | > 10% of orders = +10 pts |

**Risk levels:**
| Score | Level | Action |
|-------|-------|--------|
| 0–20 | Minimal | No action |
| 21–40 | Low | Monitor monthly |
| 41–60 | Medium | Warning email, monthly review |
| 61–80 | High | Suspend new products, assign account manager |
| 81–100 | Critical | Suspend account, manual review required |

**API:**
```
GET /v1/admin/suppliers/risk?level=high
GET /v1/admin/suppliers/:id/risk-score
POST /v1/admin/suppliers/:id/risk-action
  { action: 'warn' | 'suspend_products' | 'suspend' | 'assign_manager' }
```

---

### 3.4 Admin Supplier Product Management

Admins have full control over all supplier products across the marketplace.

**Admin capabilities:**
- View all products across all suppliers (with supplier filter)
- Approve / reject pending product submissions
- Force-deactivate a live product (policy violation, safety recall)
- Edit product metadata (category, tags, featured flag)
- Bulk operations: bulk approve, bulk deactivate

**API:**
```
GET    /v1/admin/suppliers/products?status=pending_review&supplier_id=uuid
POST   /v1/admin/suppliers/products/:id/approve
POST   /v1/admin/suppliers/products/:id/reject     { reason }
PATCH  /v1/admin/suppliers/products/:id            { is_featured, category_id, tags }
DELETE /v1/admin/suppliers/products/:id            (deactivate, not hard delete)

POST   /v1/admin/suppliers/products/bulk-approve   { product_ids: [] }
POST   /v1/admin/suppliers/products/bulk-deactivate { product_ids: [], reason }
```

---

## 4. Database Schema (additions)

```sql
CREATE TABLE supplier_applications (
  id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_name     VARCHAR(255) NOT NULL,
  contact_name     VARCHAR(255) NOT NULL,
  email            VARCHAR(255) NOT NULL UNIQUE,
  phone            VARCHAR(30),
  category         VARCHAR(100),
  cr_number        VARCHAR(50)  UNIQUE,
  status           VARCHAR(30)  NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  documents        JSONB,
  reviewed_by      UUID        REFERENCES users(id),
  reviewed_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE review_replies (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  review_id   UUID        NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  supplier_id UUID        NOT NULL REFERENCES users(id),
  message     TEXT        NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE supplier_risk_scores (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  supplier_id  UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  score        INT         NOT NULL,
  level        VARCHAR(20) NOT NULL,
  factors      JSONB,
  calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_supplier_apps_status ON supplier_applications (status);
CREATE INDEX idx_review_replies       ON review_replies (review_id);
CREATE INDEX idx_risk_scores          ON supplier_risk_scores (supplier_id, calculated_at DESC);
```

---

## 5. Flutter App Structure

```
lib/features/supplier/presentation/
  supplier_login_screen.dart            — Supplier authentication + apply form
  supplier_dashboard_screen.dart        — KPIs, quick actions, recent orders
  supplier_product_submission_screen.dart — 4-tab product submission form
  supplier_inventory_screen.dart        — Stock management with adjust sheet
  supplier_purchase_orders_screen.dart  — PO list with accept/ship actions
  supplier_shipment_tracking_screen.dart — Unified shipment tracking view
  supplier_analytics_screen.dart        — Revenue, products, customer tabs
  supplier_ratings_screen.dart          — Reviews, reply, sentiment summary
  supplier_payout_screen.dart           — Balance, payout history, transactions

lib/features/admin/presentation/suppliers/
  supplier_approval_screen.dart         — Application review queue
  supplier_performance_screen.dart      — Rankings + benchmark comparison
  supplier_risk_score_screen.dart       — Risk scores + action controls
  supplier_product_management_screen.dart — Cross-supplier product admin
```

---

## 6. Commission & Payout Model

| Tier | Monthly GMV | Commission Rate |
|------|-------------|-----------------|
| Standard | < QAR 10,000 | 12% |
| Silver | QAR 10,000 – 50,000 | 10% |
| Gold | QAR 50,000 – 200,000 | 8% |
| Platinum | > QAR 200,000 | 6% |

Commission tier is calculated on the prior month's GMV and applied for the current month. Stored in `supplier_commission_tiers` table.

---

## 7. Notifications

| Event | Channel |
|-------|---------|
| Application approved/rejected | Email + Push |
| Product approved/rejected | Email + Push |
| New purchase order | Push (high priority) |
| Stock below reorder point | Push + Email |
| Payout processed | Email |
| Rating below 4.0 | Email |
| Risk score elevated | Email |

---

## 8. Environment Variables

```env
SUPPLIER_MIN_PAYOUT=100.00
SUPPLIER_COMMISSION_STANDARD=0.12
SUPPLIER_COMMISSION_SILVER=0.10
SUPPLIER_COMMISSION_GOLD=0.08
SUPPLIER_COMMISSION_PLATINUM=0.06
SUPPLIER_PAYOUT_DAY_1=1
SUPPLIER_PAYOUT_DAY_2=15
SUPPLIER_EARLY_PAYOUT_FEE=15.00
SUPPLIER_RISK_SCORE_CRON=0 3 * * *   # nightly at 3 AM
```
