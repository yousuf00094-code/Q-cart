# Q Cart – Backend

REST API backend for the Q Cart e-commerce platform (Qatar).

## Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js 20 LTS |
| Framework | Fastify 4 |
| Database | PostgreSQL 15 |
| Auth | JWT (access) + HTTP-only cookie (refresh) |
| File storage | S3-compatible (AWS S3 / MinIO) |
| Cache | Redis 7 |
| Email | SMTP via Nodemailer |
| Payment | QPay / Stripe |

## Repository layout

```
backend/
├── postgresql/
│   └── schema.sql        # Full DDL – run once on a fresh database
├── src/
│   ├── config/           # Environment, database pool, Redis client
│   ├── plugins/          # Fastify plugins (auth, error-handler, cors)
│   ├── routes/           # One file per resource (auth, products, orders, …)
│   ├── services/         # Business logic layer
│   ├── repositories/     # SQL queries (no ORM)
│   └── utils/            # Helpers (jwt, hashing, pagination, …)
├── migrations/           # Numbered SQL migration files
├── seeds/                # Dev seed data
└── README.md
```

## Prerequisites

- PostgreSQL 15+
- Node.js 20+
- Redis 7+

## Local setup

### 1. Clone and install

```bash
git clone https://github.com/yousuf00094-code/Q-cart.git
cd Q-cart/backend
npm install
```

### 2. Environment variables

Copy `.env.example` to `.env` and fill in the values:

```env
# Server
PORT=3000
NODE_ENV=development

# PostgreSQL
DATABASE_URL=postgresql://qcart:secret@localhost:5432/qcart

# Redis
REDIS_URL=redis://localhost:6379

# JWT
JWT_ACCESS_SECRET=change_me_access_secret
JWT_REFRESH_SECRET=change_me_refresh_secret
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d

# AWS S3 / MinIO
S3_ENDPOINT=https://s3.amazonaws.com
S3_BUCKET=qcart-media
S3_REGION=me-south-1
S3_ACCESS_KEY=your_key
S3_SECRET_KEY=your_secret
CDN_BASE_URL=https://cdn.qcart.qa

# Email
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@qcart.qa
SMTP_PASS=smtp_password
EMAIL_FROM="Q Cart <noreply@qcart.qa>"

# Payment
QPAY_MERCHANT_ID=your_merchant_id
QPAY_SECRET=your_qpay_secret

# Webhooks
WEBHOOK_SECRET=change_me_webhook_secret
```

### 3. Create and seed the database

```bash
# Create database
createdb qcart

# Apply schema (idempotent on a fresh DB)
psql -d qcart -f postgresql/schema.sql

# Seed development data (optional)
npm run db:seed
```

### 4. Run

```bash
# Development (hot-reload)
npm run dev

# Production
npm start
```

API will be available at `http://localhost:3000/v1`.

## Database migrations

New migrations go in `migrations/` numbered sequentially:

```
migrations/
  0001_initial_schema.sql
  0002_add_referral_codes.sql
  …
```

Run pending migrations:

```bash
npm run migrate
```

Roll back the last migration:

```bash
npm run migrate:rollback
```

## Testing

```bash
npm test            # unit + integration tests
npm run test:watch  # watch mode
npm run test:cov    # coverage report
```

Integration tests use a separate `qcart_test` database. The test runner resets it before each run via `BEGIN` / `ROLLBACK` transactions.

## API documentation

Interactive docs are served at `http://localhost:3000/docs` when `NODE_ENV=development` (Swagger UI auto-generated from Fastify schemas).

See [`../docs/api-specification.md`](../docs/api-specification.md) for the full human-readable spec.  
See [`../docs/database-schema.md`](../docs/database-schema.md) for the full database reference.

## Key design decisions

**No ORM.** All queries use raw SQL via `postgres` (node-postgres). This gives full control over query plans, CTEs, and PostgreSQL-specific features (JSONB, arrays, GIN indexes, triggers).

**Cursor pagination by default.** Product and order lists use keyset pagination for consistent performance at large offsets. Admin endpoints use offset pagination for simplicity.

**Price snapshots.** `order_items.unit_price`, `order_items.product_name`, and `orders.address_snapshot` are all snapshotted at order creation time so historical orders remain accurate when products or addresses are edited later.

**Inventory reservation.** When an order is placed, `inventory.reserved` is incremented immediately via a database trigger. This prevents overselling under concurrent load without requiring application-level locking.

**Guest carts.** Carts can be owned by an unauthenticated session (`session_id`). On login, the guest cart is merged into the user's cart automatically.

## Security checklist

- [x] Passwords hashed with bcrypt (cost factor 12)
- [x] JWT signed with RS256 (asymmetric keys in production)
- [x] Refresh tokens stored as SHA-256 hashes in the DB
- [x] HTTP-only, Secure, SameSite=Strict cookie for refresh token
- [x] Rate limiting on all auth endpoints (5 req/min per IP)
- [x] SQL injection prevented by parameterised queries throughout
- [x] Input validated with JSON Schema on every route
- [x] File uploads virus-scanned before S3 storage
- [x] Webhook signatures verified with HMAC-SHA256
- [x] `cost_price` field stripped from all customer-facing responses
