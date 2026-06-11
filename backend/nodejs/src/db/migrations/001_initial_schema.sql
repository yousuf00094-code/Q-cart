-- Q Cart — initial database schema
-- Run once against a fresh PostgreSQL 15+ database.
-- Idempotent: safe to apply with CREATE IF NOT EXISTS guards.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ── Enums ─────────────────────────────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE user_role       AS ENUM ('customer', 'admin', 'supplier');
  EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE order_status    AS ENUM ('pending','confirmed','processing','packed','out_for_delivery','delivered','cancelled','refunded');
  EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE payment_method  AS ENUM ('card','cash_on_delivery','apple_pay','google_pay','qpay');
  EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE payment_status  AS ENUM ('pending','paid','failed','refunded');
  EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE discount_type   AS ENUM ('percentage','fixed');
  EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE supplier_status AS ENUM ('active','inactive','pending_approval');
  EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE inventory_txn   AS ENUM ('restock','sale','adjustment','return','damage');
  EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE notif_type      AS ENUM ('order_update','promotion','review_reply','loyalty','system');
  EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── Users ─────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS users (
  id                     UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name              VARCHAR(120) NOT NULL,
  email                  VARCHAR(255) NOT NULL UNIQUE,
  phone                  VARCHAR(20)  UNIQUE,
  password_hash          TEXT         NOT NULL,
  role                   user_role    NOT NULL DEFAULT 'customer',
  avatar_url             TEXT,
  is_email_verified      BOOLEAN      NOT NULL DEFAULT FALSE,
  is_active              BOOLEAN      NOT NULL DEFAULT TRUE,
  refresh_token_hash     TEXT,
  password_reset_token   TEXT,
  password_reset_expires TIMESTAMPTZ,
  last_login_at          TIMESTAMPTZ,
  created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_role  ON users (role);

-- ── Suppliers ─────────────────────────────────────────────────────────────────
-- user_id links a supplier entity to the users table for role-based access control

CREATE TABLE IF NOT EXISTS suppliers (
  id             UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID            REFERENCES users(id) ON DELETE SET NULL,
  name           VARCHAR(150)    NOT NULL,
  email          VARCHAR(255)    NOT NULL UNIQUE,
  phone          VARCHAR(20),
  address        TEXT,
  contact_person VARCHAR(120),
  logo_url       TEXT,
  status         supplier_status NOT NULL DEFAULT 'pending_approval',
  rating         NUMERIC(3,2)    CHECK (rating >= 0 AND rating <= 5),
  notes          TEXT,
  created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_suppliers_status  ON suppliers (status);
CREATE INDEX IF NOT EXISTS idx_suppliers_email   ON suppliers (email);
CREATE INDEX IF NOT EXISTS idx_suppliers_user_id ON suppliers (user_id);

-- ── Categories ────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS categories (
  id          UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        VARCHAR(100) NOT NULL,
  slug        VARCHAR(120) NOT NULL UNIQUE,
  description TEXT,
  image_url   TEXT,
  parent_id   UUID         REFERENCES categories(id) ON DELETE SET NULL,
  sort_order  SMALLINT     NOT NULL DEFAULT 0,
  is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories (parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_slug      ON categories (slug);

-- ── Products ──────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS products (
  id                UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id       UUID          NOT NULL REFERENCES categories(id),
  supplier_id       UUID          REFERENCES suppliers(id) ON DELETE SET NULL,
  name              VARCHAR(255)  NOT NULL,
  slug              VARCHAR(280)  NOT NULL UNIQUE,
  description       TEXT,
  short_description VARCHAR(500),
  sku               VARCHAR(100)  UNIQUE,
  barcode           VARCHAR(100),
  price             NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  compare_at_price  NUMERIC(10,2) CHECK (compare_at_price >= 0),
  cost_price        NUMERIC(10,2) CHECK (cost_price >= 0),
  weight_grams      INT           CHECK (weight_grams > 0),
  images            JSONB         NOT NULL DEFAULT '[]',
  attributes        JSONB         NOT NULL DEFAULT '{}',
  tags              TEXT[]        NOT NULL DEFAULT '{}',
  is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
  is_featured       BOOLEAN       NOT NULL DEFAULT FALSE,
  average_rating    NUMERIC(3,2)  NOT NULL DEFAULT 0,
  review_count      INT           NOT NULL DEFAULT 0,
  total_sold        INT           NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_category_id ON products (category_id);
CREATE INDEX IF NOT EXISTS idx_products_supplier_id ON products (supplier_id);
CREATE INDEX IF NOT EXISTS idx_products_slug        ON products (slug);
CREATE INDEX IF NOT EXISTS idx_products_sku         ON products (sku);
CREATE INDEX IF NOT EXISTS idx_products_is_active   ON products (is_active);
CREATE INDEX IF NOT EXISTS idx_products_created_at  ON products (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_name_trgm   ON products USING GIN (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_tags        ON products USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_products_attributes  ON products USING GIN (attributes);

-- ── Inventory ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS inventory (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id    UUID        NOT NULL UNIQUE REFERENCES products(id) ON DELETE CASCADE,
  quantity      INT         NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  reserved      INT         NOT NULL DEFAULT 0 CHECK (reserved >= 0),
  reorder_point INT         NOT NULL DEFAULT 5,
  reorder_qty   INT         NOT NULL DEFAULT 20,
  warehouse_loc VARCHAR(100),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inventory_product_id ON inventory (product_id);

CREATE TABLE IF NOT EXISTS inventory_transactions (
  id             UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id     UUID          NOT NULL REFERENCES products(id),
  txn_type       inventory_txn NOT NULL,
  quantity_delta INT           NOT NULL,
  quantity_after INT           NOT NULL,
  reference_id   UUID,
  notes          TEXT,
  created_by     UUID          REFERENCES users(id) ON DELETE SET NULL,
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inv_txn_product_id ON inventory_transactions (product_id);
CREATE INDEX IF NOT EXISTS idx_inv_txn_created_at ON inventory_transactions (created_at DESC);

-- ── Addresses ─────────────────────────────────────────────────────────────────
-- Column names match address.model.js (first_name / last_name split, address_line1/2)

CREATE TABLE IF NOT EXISTS addresses (
  id            UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label         VARCHAR(60)  NOT NULL DEFAULT 'Home',
  first_name    VARCHAR(60)  NOT NULL,
  last_name     VARCHAR(60)  NOT NULL,
  phone         VARCHAR(20),
  address_line1 VARCHAR(255) NOT NULL,
  address_line2 VARCHAR(255),
  city          VARCHAR(100) NOT NULL,
  state         VARCHAR(100),
  country       VARCHAR(80)  NOT NULL DEFAULT 'QA',
  postal_code   VARCHAR(20),
  latitude      NUMERIC(9,6),
  longitude     NUMERIC(9,6),
  is_default    BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON addresses (user_id);
-- Partial unique index: only one default per user allowed
CREATE UNIQUE INDEX IF NOT EXISTS idx_addresses_one_default ON addresses (user_id) WHERE is_default = TRUE;

-- ── Coupons ───────────────────────────────────────────────────────────────────

CREATE SEQUENCE IF NOT EXISTS order_seq START 100000;

CREATE TABLE IF NOT EXISTS coupons (
  id                  UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  code                VARCHAR(50)   NOT NULL UNIQUE,
  description         TEXT,
  discount_type       discount_type NOT NULL,
  discount_value      NUMERIC(10,2) NOT NULL CHECK (discount_value > 0),
  min_order_amount    NUMERIC(10,2) NOT NULL DEFAULT 0,
  max_discount_amount NUMERIC(10,2),
  usage_limit         INT,
  usage_count         INT           NOT NULL DEFAULT 0,
  per_user_limit      INT           NOT NULL DEFAULT 1,
  is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
  valid_from          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  valid_until         TIMESTAMPTZ,
  created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_coupons_code      ON coupons (UPPER(code));
CREATE INDEX IF NOT EXISTS idx_coupons_is_active ON coupons (is_active);

-- ── Carts ─────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS carts (
  id         UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID         UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  session_id VARCHAR(120) UNIQUE,
  coupon_id  UUID         REFERENCES coupons(id) ON DELETE SET NULL,
  expires_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  CONSTRAINT carts_owner_check CHECK (
    (user_id IS NOT NULL AND session_id IS NULL) OR
    (user_id IS NULL     AND session_id IS NOT NULL)
  )
);

CREATE TABLE IF NOT EXISTS cart_items (
  id         UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  cart_id    UUID          NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
  product_id UUID          NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity   INT           NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10,2),
  added_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  UNIQUE (cart_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_cart_items_cart_id ON cart_items (cart_id);

-- ── Orders ────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS orders (
  id                  UUID           PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id             UUID           NOT NULL REFERENCES users(id),
  address_id          UUID           REFERENCES addresses(id) ON DELETE SET NULL,
  coupon_id           UUID           REFERENCES coupons(id) ON DELETE SET NULL,
  order_number        VARCHAR(30)    NOT NULL UNIQUE,
  status              order_status   NOT NULL DEFAULT 'pending',
  payment_method      payment_method NOT NULL,
  payment_status      payment_status NOT NULL DEFAULT 'pending',
  payment_reference   VARCHAR(200),
  subtotal            NUMERIC(10,2)  NOT NULL,
  discount_amount     NUMERIC(10,2)  NOT NULL DEFAULT 0,
  delivery_fee        NUMERIC(10,2)  NOT NULL DEFAULT 0,
  total               NUMERIC(10,2)  NOT NULL,
  address_snapshot    JSONB          NOT NULL DEFAULT '{}',
  notes               TEXT,
  estimated_delivery  TIMESTAMPTZ,
  delivered_at        TIMESTAMPTZ,
  cancelled_at        TIMESTAMPTZ,
  cancellation_reason TEXT,
  created_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_user_id    ON orders (user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status     ON orders (status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders (created_at DESC);

CREATE TABLE IF NOT EXISTS order_items (
  id            UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id      UUID          NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id    UUID          REFERENCES products(id) ON DELETE SET NULL,
  supplier_id   UUID          REFERENCES suppliers(id) ON DELETE SET NULL,
  product_name  VARCHAR(255)  NOT NULL,
  product_sku   VARCHAR(100),
  product_image TEXT,
  quantity      INT           NOT NULL CHECK (quantity > 0),
  unit_price    NUMERIC(10,2) NOT NULL,
  total_price   NUMERIC(10,2) NOT NULL,
  is_reviewed   BOOLEAN       NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id   ON order_items (order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items (product_id);

-- ── Reviews ───────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS reviews (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id    UUID        NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id       UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  order_id      UUID        REFERENCES orders(id) ON DELETE SET NULL,
  rating        SMALLINT    NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title         VARCHAR(200),
  body          TEXT,
  images        JSONB       NOT NULL DEFAULT '[]',
  is_verified   BOOLEAN     NOT NULL DEFAULT FALSE,
  is_approved   BOOLEAN     NOT NULL DEFAULT TRUE,
  helpful_count INT         NOT NULL DEFAULT 0,
  reply         TEXT,
  replied_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (product_id, user_id, order_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews (product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id    ON reviews (user_id);

-- ── Wishlist ──────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS wishlist (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID        NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  added_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_wishlist_user_id ON wishlist (user_id);

-- ── Loyalty points ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS loyalty_points (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  order_id      UUID        REFERENCES orders(id) ON DELETE SET NULL,
  points_delta  INT         NOT NULL,
  balance_after INT         NOT NULL CHECK (balance_after >= 0),
  description   TEXT,
  expires_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_loyalty_user_id ON loyalty_points (user_id);

CREATE OR REPLACE VIEW loyalty_balances AS
  SELECT user_id, COALESCE(SUM(points_delta), 0) AS balance
    FROM loyalty_points
   WHERE expires_at IS NULL OR expires_at > NOW()
   GROUP BY user_id;

-- ── Notifications ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS notifications (
  id         UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       notif_type   NOT NULL,
  title      VARCHAR(200) NOT NULL,
  body       TEXT,
  data       JSONB        NOT NULL DEFAULT '{}',
  is_read    BOOLEAN      NOT NULL DEFAULT FALSE,
  read_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread  ON notifications (user_id) WHERE is_read = FALSE;

-- ── Triggers ──────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$;

DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'users','suppliers','categories','products','addresses',
    'coupons','carts','cart_items','orders','reviews'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_' || t || '_updated_at'
    ) THEN
      EXECUTE format(
        'CREATE TRIGGER trg_%s_updated_at
         BEFORE UPDATE ON %s
         FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
        t, t
      );
    END IF;
  END LOOP;
END; $$;

-- Auto-generate QC-XXXXXX order numbers
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.order_number := 'QC-' || LPAD(nextval('order_seq')::TEXT, 6, '0');
  RETURN NEW;
END; $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_order_number') THEN
    CREATE TRIGGER trg_order_number
    BEFORE INSERT ON orders
    FOR EACH ROW EXECUTE FUNCTION generate_order_number();
  END IF;
END; $$;

-- Keep products.average_rating and review_count in sync automatically
CREATE OR REPLACE FUNCTION refresh_product_rating()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE p_id UUID;
BEGIN
  p_id := COALESCE(NEW.product_id, OLD.product_id);
  UPDATE products
     SET average_rating = COALESCE((
           SELECT ROUND(AVG(rating)::NUMERIC, 2)
             FROM reviews
            WHERE product_id = p_id AND is_approved = TRUE
         ), 0),
         review_count = (
           SELECT COUNT(*)
             FROM reviews
            WHERE product_id = p_id AND is_approved = TRUE
         )
   WHERE id = p_id;
  RETURN NULL;
END; $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_review_stats') THEN
    CREATE TRIGGER trg_review_stats
    AFTER INSERT OR UPDATE OR DELETE ON reviews
    FOR EACH ROW EXECUTE FUNCTION refresh_product_rating();
  END IF;
END; $$;
