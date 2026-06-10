# Q Cart – Database Schema Reference

**Database:** PostgreSQL 15+  
**Extensions:** `uuid-ossp`, `pgcrypto`, `pg_trgm`

---

## Entity Relationship Overview

```
users ──────────────┬── addresses (1:N)
                    ├── carts (1:1)
                    ├── orders (1:N)
                    ├── reviews (1:N)
                    ├── wishlist (1:N)
                    ├── loyalty_points (1:N)
                    └── notifications (1:N)

categories ─────────┬── categories (self-referential, parent_id)
                    └── products (1:N)

suppliers ──────────── products (1:N)

products ───────────┬── inventory (1:1)
                    ├── cart_items (1:N)
                    ├── order_items (1:N)
                    ├── reviews (1:N)
                    └── wishlist (1:N)

carts ──────────────── cart_items (1:N)
orders ─────────────── order_items (1:N)
coupons ────────────┬── carts (1:N)
                    └── orders (1:N)
```

---

## Tables

### `users`

Stores all registered users (customers, admins, suppliers).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, default `uuid_generate_v4()` | Unique identifier |
| `full_name` | VARCHAR(120) | NOT NULL | Display name |
| `email` | VARCHAR(255) | NOT NULL, UNIQUE | Login identifier |
| `phone` | VARCHAR(20) | UNIQUE | Qatar mobile number |
| `password_hash` | TEXT | NOT NULL | bcrypt hash |
| `role` | user_role | NOT NULL, default `customer` | `customer` \| `admin` \| `supplier` |
| `avatar_url` | TEXT | — | Profile picture URL |
| `is_email_verified` | BOOLEAN | NOT NULL, default `false` | Email verification gate |
| `is_active` | BOOLEAN | NOT NULL, default `true` | Soft-disable without deletion |
| `refresh_token_hash` | TEXT | — | Current JWT refresh token hash |
| `last_login_at` | TIMESTAMPTZ | — | Last successful login |
| `created_at` | TIMESTAMPTZ | NOT NULL | Row creation time |
| `updated_at` | TIMESTAMPTZ | NOT NULL | Auto-updated by trigger |

**Indexes:** `email`, `phone`, `role`

---

### `categories`

Self-referential tree for product categories (supports one level of nesting).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK | — |
| `name` | VARCHAR(100) | NOT NULL | Display name |
| `slug` | VARCHAR(120) | NOT NULL, UNIQUE | URL-safe identifier |
| `description` | TEXT | — | Short description |
| `image_url` | TEXT | — | Category banner |
| `parent_id` | UUID | FK → categories(id), SET NULL | NULL = root category |
| `sort_order` | SMALLINT | NOT NULL, default 0 | Display ordering |
| `is_active` | BOOLEAN | NOT NULL, default `true` | Hide from storefront |

**Indexes:** `parent_id`, `slug`

---

### `suppliers`

Companies or individuals supplying products to Q Cart.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK | — |
| `name` | VARCHAR(150) | NOT NULL | Company name |
| `email` | VARCHAR(255) | NOT NULL, UNIQUE | Contact email |
| `phone` | VARCHAR(20) | — | Contact number |
| `address` | TEXT | — | Physical address |
| `contact_person` | VARCHAR(120) | — | Primary contact |
| `logo_url` | TEXT | — | Supplier logo |
| `status` | supplier_status | NOT NULL | `active` \| `inactive` \| `pending_approval` |
| `rating` | NUMERIC(3,2) | CHECK 0–5 | Average fulfilment rating |
| `notes` | TEXT | — | Internal admin notes |

**Indexes:** `status`, `email`

---

### `products`

Master product catalogue.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK | — |
| `category_id` | UUID | NOT NULL, FK → categories | Product category |
| `supplier_id` | UUID | FK → suppliers, SET NULL | Supplying company |
| `name` | VARCHAR(255) | NOT NULL | Display name |
| `slug` | VARCHAR(280) | NOT NULL, UNIQUE | URL path segment |
| `description` | TEXT | — | Long description (HTML/Markdown) |
| `short_description` | VARCHAR(500) | — | Card-level teaser |
| `sku` | VARCHAR(100) | UNIQUE | Stock keeping unit |
| `barcode` | VARCHAR(100) | — | EAN/UPC barcode |
| `price` | NUMERIC(10,2) | NOT NULL, ≥ 0 | Current selling price (QAR) |
| `compare_at_price` | NUMERIC(10,2) | ≥ 0 | Strikethrough price |
| `cost_price` | NUMERIC(10,2) | ≥ 0 | Internal cost (hidden from API) |
| `weight_grams` | INT | > 0 | For delivery fee calculation |
| `images` | JSONB | NOT NULL, default `[]` | Array of `{url, alt, sort}` |
| `attributes` | JSONB | NOT NULL, default `{}` | `{color, size, brand, …}` |
| `tags` | TEXT[] | NOT NULL, default `{}` | Searchable tags |
| `is_active` | BOOLEAN | NOT NULL | Storefront visibility |
| `is_featured` | BOOLEAN | NOT NULL | Home-page feature flag |
| `average_rating` | NUMERIC(3,2) | Auto-updated by trigger | Aggregate review score |
| `review_count` | INT | Auto-updated by trigger | Total approved reviews |
| `total_sold` | INT | NOT NULL | Lifetime units sold |

**Indexes:** `category_id`, `supplier_id`, `slug`, `sku`, `is_active`, `is_featured` (partial), GIN on `name` (trigram), `tags`, `attributes`

---

### `inventory`

Current stock levels per product (one-to-one with `products`).

| Column | Type | Description |
|---|---|---|
| `id` | UUID | PK |
| `product_id` | UUID | UNIQUE FK → products |
| `quantity` | INT | Total physical stock, ≥ 0 |
| `reserved` | INT | Quantity committed to open orders, ≥ 0 |
| `reorder_point` | INT | Alert threshold |
| `reorder_qty` | INT | Suggested restock quantity |
| `warehouse_loc` | VARCHAR(100) | Bin/shelf reference |
| `updated_at` | TIMESTAMPTZ | Last stock change |

**Derived:** `available = quantity - reserved`

**Indexes:** `product_id`, partial index on `quantity <= reorder_point` for low-stock alerts

### `inventory_transactions`

Immutable audit log for every stock movement.

| Column | Type | Description |
|---|---|---|
| `id` | UUID | PK |
| `product_id` | UUID | FK → products |
| `txn_type` | inventory_txn | `restock` \| `sale` \| `adjustment` \| `return` \| `damage` |
| `quantity_delta` | INT | Positive = stock in, negative = stock out |
| `quantity_after` | INT | Snapshot after the movement |
| `reference_id` | UUID | Related order or delivery ID |
| `notes` | TEXT | Free-form reason |
| `created_by` | UUID | FK → users (admin who made adjustment) |
| `created_at` | TIMESTAMPTZ | — |

---

### `addresses`

Saved delivery addresses per user. Enforces a single default via partial unique index.

| Column | Type | Description |
|---|---|---|
| `id` | UUID | PK |
| `user_id` | UUID | FK → users |
| `label` | VARCHAR(60) | User-defined name |
| `type` | address_type | `home` \| `work` \| `other` |
| `full_name` | VARCHAR(120) | Recipient name |
| `phone` | VARCHAR(20) | Recipient phone |
| `line1` | VARCHAR(255) | Street / building |
| `line2` | VARCHAR(255) | Floor / apartment |
| `city` | VARCHAR(100) | Default: Doha |
| `area` | VARCHAR(100) | Neighbourhood / zone |
| `country` | VARCHAR(80) | Default: Qatar |
| `latitude` | NUMERIC(9,6) | GPS coordinate |
| `longitude` | NUMERIC(9,6) | GPS coordinate |
| `is_default` | BOOLEAN | Unique per user via partial index |

---

### `coupons`

Discount codes applicable at checkout.

| Column | Type | Description |
|---|---|---|
| `id` | UUID | PK |
| `code` | VARCHAR(50) | UNIQUE, case-insensitive at app layer |
| `discount_type` | discount_type | `percentage` \| `fixed` |
| `discount_value` | NUMERIC(10,2) | Amount or percentage points |
| `min_order_amount` | NUMERIC(10,2) | Minimum cart value |
| `max_discount_amount` | NUMERIC(10,2) | Cap for percentage coupons |
| `usage_limit` | INT | NULL = unlimited total uses |
| `usage_count` | INT | Incremented atomically on redemption |
| `per_user_limit` | INT | Default 1 |
| `valid_from` | TIMESTAMPTZ | Activation date |
| `valid_until` | TIMESTAMPTZ | Expiry date (NULL = no expiry) |

---

### `carts` / `cart_items`

Supports both authenticated users (linked by `user_id`) and guests (linked by `session_id`). A check constraint enforces mutual exclusivity.

**`carts`**

| Column | Type | Description |
|---|---|---|
| `id` | UUID | PK |
| `user_id` | UUID | UNIQUE FK → users (nullable) |
| `session_id` | VARCHAR(120) | UNIQUE guest token (nullable) |
| `coupon_id` | UUID | FK → coupons |
| `expires_at` | TIMESTAMPTZ | Guest cart TTL |

**`cart_items`**

| Column | Type | Description |
|---|---|---|
| `id` | UUID | PK |
| `cart_id` | UUID | FK → carts |
| `product_id` | UUID | FK → products |
| `quantity` | INT | > 0 |
| `unit_price` | NUMERIC(10,2) | Price at add-to-cart time (snapshot) |

UNIQUE constraint on `(cart_id, product_id)`.

---

### `orders` / `order_items`

Immutable record of every placed order. Address is snapshotted into `address_snapshot` JSONB at creation time so edits to the saved address do not affect historical orders.

**`orders`**

| Column | Type | Description |
|---|---|---|
| `id` | UUID | PK |
| `user_id` | UUID | FK → users |
| `address_id` | UUID | FK → addresses |
| `coupon_id` | UUID | FK → coupons |
| `order_number` | VARCHAR(30) | Auto-generated `QC-XXXXXX` |
| `status` | order_status | See enum values below |
| `payment_method` | payment_method | — |
| `payment_status` | payment_status | — |
| `payment_reference` | VARCHAR(200) | Gateway transaction ID |
| `subtotal` | NUMERIC(10,2) | Before discounts + delivery |
| `discount_amount` | NUMERIC(10,2) | Coupon / promo reduction |
| `delivery_fee` | NUMERIC(10,2) | — |
| `total` | NUMERIC(10,2) | Final charge |
| `address_snapshot` | JSONB | Denormalised address at order time |

**Order status flow:**
```
pending → confirmed → processing → packed → out_for_delivery → delivered
                 └─────────────────────────────────────────→ cancelled
delivered ──────────────────────────────────────────────────→ refunded
```

**`order_items`**

| Column | Type | Description |
|---|---|---|
| `order_id` | UUID | FK → orders |
| `product_id` | UUID | FK → products |
| `product_name` | VARCHAR(255) | Snapshot |
| `product_sku` | VARCHAR(100) | Snapshot |
| `product_image` | TEXT | Snapshot |
| `quantity` | INT | — |
| `unit_price` | NUMERIC(10,2) | Price at order time |
| `total_price` | NUMERIC(10,2) | `unit_price × quantity` |
| `is_reviewed` | BOOLEAN | Guards one-review-per-purchase |

---

### `reviews`

User product reviews gated to verified purchasers. A UNIQUE constraint on `(product_id, user_id, order_id)` prevents duplicate reviews per purchase. The `refresh_product_rating` trigger keeps `products.average_rating` and `products.review_count` in sync automatically.

| Column | Type | Description |
|---|---|---|
| `rating` | SMALLINT | 1–5, NOT NULL |
| `is_verified` | BOOLEAN | Set `true` when linked to a completed order |
| `is_approved` | BOOLEAN | Moderation gate |
| `helpful_count` | INT | Upvotes |
| `reply` | TEXT | Supplier / admin response |

---

### `wishlist`

Simple join table. UNIQUE on `(user_id, product_id)`.

---

### `loyalty_points`

Ledger table — never UPDATE, only INSERT. Balance is derived via the `loyalty_balances` view (`SUM(points_delta)` excluding expired rows).

| Column | Type | Description |
|---|---|---|
| `points_delta` | INT | +ve = earned, -ve = redeemed |
| `balance_after` | INT | Running total snapshot, ≥ 0 |
| `expires_at` | TIMESTAMPTZ | NULL = no expiry |

---

### `notifications`

Push/in-app notification inbox per user.

| Column | Type | Description |
|---|---|---|
| `type` | notif_type | `order_update` \| `promotion` \| `review_reply` \| `loyalty` \| `system` |
| `data` | JSONB | Contextual payload (order_id, product_id, etc.) |
| `is_read` | BOOLEAN | Unread count via partial index |
| `read_at` | TIMESTAMPTZ | — |

---

## Enums

| Enum | Values |
|---|---|
| `user_role` | `customer`, `admin`, `supplier` |
| `order_status` | `pending`, `confirmed`, `processing`, `packed`, `out_for_delivery`, `delivered`, `cancelled`, `refunded` |
| `payment_method` | `card`, `cash_on_delivery`, `apple_pay`, `google_pay`, `qpay` |
| `payment_status` | `pending`, `paid`, `failed`, `refunded` |
| `address_type` | `home`, `work`, `other` |
| `discount_type` | `percentage`, `fixed` |
| `notif_type` | `order_update`, `promotion`, `review_reply`, `loyalty`, `system` |
| `inventory_txn` | `restock`, `sale`, `adjustment`, `return`, `damage` |
| `supplier_status` | `active`, `inactive`, `pending_approval` |

---

## Triggers

| Trigger | Table | Event | Action |
|---|---|---|---|
| `trg_*_updated_at` | All main tables | BEFORE UPDATE | Sets `updated_at = NOW()` |
| `trg_review_stats` | `reviews` | AFTER INSERT/UPDATE/DELETE | Recalculates `products.average_rating` + `review_count` |
| `trg_reserve_inventory` | `order_items` | AFTER INSERT | Increments `inventory.reserved` |
| `trg_order_number` | `orders` | BEFORE INSERT | Generates `QC-XXXXXX` from `order_seq` |
