-- =============================================================
-- Q Cart – PostgreSQL Database Schema
-- =============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";   -- fuzzy product search

-- =============================================================
-- ENUMS
-- =============================================================

CREATE TYPE user_role       AS ENUM ('customer', 'admin', 'supplier');
CREATE TYPE order_status    AS ENUM ('pending', 'confirmed', 'processing', 'packed', 'out_for_delivery', 'delivered', 'cancelled', 'refunded');
CREATE TYPE payment_method  AS ENUM ('card', 'cash_on_delivery', 'apple_pay', 'google_pay', 'qpay');
CREATE TYPE payment_status  AS ENUM ('pending', 'paid', 'failed', 'refunded');
CREATE TYPE address_type    AS ENUM ('home', 'work', 'other');
CREATE TYPE discount_type   AS ENUM ('percentage', 'fixed');
CREATE TYPE notif_type      AS ENUM ('order_update', 'promotion', 'review_reply', 'loyalty', 'system');
CREATE TYPE inventory_txn   AS ENUM ('restock', 'sale', 'adjustment', 'return', 'damage');
CREATE TYPE supplier_status AS ENUM ('active', 'inactive', 'pending_approval');

-- =============================================================
-- USERS
-- =============================================================

CREATE TABLE users (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name           VARCHAR(120)    NOT NULL,
    email               VARCHAR(255)    NOT NULL UNIQUE,
    phone               VARCHAR(20)     UNIQUE,
    password_hash       TEXT            NOT NULL,
    role                user_role       NOT NULL DEFAULT 'customer',
    avatar_url          TEXT,
    is_email_verified   BOOLEAN         NOT NULL DEFAULT FALSE,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    refresh_token_hash  TEXT,
    last_login_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email   ON users (email);
CREATE INDEX idx_users_phone   ON users (phone);
CREATE INDEX idx_users_role    ON users (role);

-- =============================================================
-- CATEGORIES
-- =============================================================

CREATE TABLE categories (
    id          UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(100)    NOT NULL,
    slug        VARCHAR(120)    NOT NULL UNIQUE,
    description TEXT,
    image_url   TEXT,
    parent_id   UUID            REFERENCES categories (id) ON DELETE SET NULL,
    sort_order  SMALLINT        NOT NULL DEFAULT 0,
    is_active   BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categories_parent   ON categories (parent_id);
CREATE INDEX idx_categories_slug     ON categories (slug);

-- =============================================================
-- SUPPLIERS
-- =============================================================

CREATE TABLE suppliers (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(150)    NOT NULL,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    phone           VARCHAR(20),
    address         TEXT,
    contact_person  VARCHAR(120),
    logo_url        TEXT,
    status          supplier_status NOT NULL DEFAULT 'pending_approval',
    rating          NUMERIC(3,2)    CHECK (rating >= 0 AND rating <= 5),
    notes           TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_suppliers_status ON suppliers (status);
CREATE INDEX idx_suppliers_email  ON suppliers (email);

-- =============================================================
-- PRODUCTS
-- =============================================================

CREATE TABLE products (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id         UUID            NOT NULL REFERENCES categories (id) ON DELETE RESTRICT,
    supplier_id         UUID            REFERENCES suppliers (id) ON DELETE SET NULL,
    name                VARCHAR(255)    NOT NULL,
    slug                VARCHAR(280)    NOT NULL UNIQUE,
    description         TEXT,
    short_description   VARCHAR(500),
    sku                 VARCHAR(100)    UNIQUE,
    barcode             VARCHAR(100),
    price               NUMERIC(10,2)   NOT NULL CHECK (price >= 0),
    compare_at_price    NUMERIC(10,2)   CHECK (compare_at_price >= 0),
    cost_price          NUMERIC(10,2)   CHECK (cost_price >= 0),
    weight_grams        INT             CHECK (weight_grams > 0),
    images              JSONB           NOT NULL DEFAULT '[]',   -- [{url, alt, sort}]
    attributes          JSONB           NOT NULL DEFAULT '{}',   -- {color, size, …}
    tags                TEXT[]          NOT NULL DEFAULT '{}',
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    is_featured         BOOLEAN         NOT NULL DEFAULT FALSE,
    average_rating      NUMERIC(3,2)    NOT NULL DEFAULT 0 CHECK (average_rating >= 0 AND average_rating <= 5),
    review_count        INT             NOT NULL DEFAULT 0 CHECK (review_count >= 0),
    total_sold          INT             NOT NULL DEFAULT 0 CHECK (total_sold >= 0),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_category     ON products (category_id);
CREATE INDEX idx_products_supplier     ON products (supplier_id);
CREATE INDEX idx_products_slug         ON products (slug);
CREATE INDEX idx_products_sku          ON products (sku);
CREATE INDEX idx_products_active       ON products (is_active);
CREATE INDEX idx_products_featured     ON products (is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_products_name_trgm    ON products USING gin (name gin_trgm_ops);
CREATE INDEX idx_products_tags         ON products USING gin (tags);
CREATE INDEX idx_products_attributes   ON products USING gin (attributes);

-- =============================================================
-- INVENTORY
-- =============================================================

CREATE TABLE inventory (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id      UUID            NOT NULL UNIQUE REFERENCES products (id) ON DELETE CASCADE,
    quantity        INT             NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    reserved        INT             NOT NULL DEFAULT 0 CHECK (reserved >= 0),
    reorder_point   INT             NOT NULL DEFAULT 10,
    reorder_qty     INT             NOT NULL DEFAULT 50,
    warehouse_loc   VARCHAR(100),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_inventory_product    ON inventory (product_id);
CREATE INDEX idx_inventory_low_stock  ON inventory (quantity) WHERE quantity <= reorder_point;

CREATE TABLE inventory_transactions (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id      UUID            NOT NULL REFERENCES products (id) ON DELETE CASCADE,
    txn_type        inventory_txn   NOT NULL,
    quantity_delta  INT             NOT NULL,
    quantity_after  INT             NOT NULL,
    reference_id    UUID,           -- order_id or supplier delivery id
    notes           TEXT,
    created_by      UUID            REFERENCES users (id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_inv_txn_product   ON inventory_transactions (product_id);
CREATE INDEX idx_inv_txn_type      ON inventory_transactions (txn_type);
CREATE INDEX idx_inv_txn_created   ON inventory_transactions (created_at DESC);

-- =============================================================
-- ADDRESSES
-- =============================================================

CREATE TABLE addresses (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    label           VARCHAR(60),
    type            address_type    NOT NULL DEFAULT 'home',
    full_name       VARCHAR(120)    NOT NULL,
    phone           VARCHAR(20)     NOT NULL,
    line1           VARCHAR(255)    NOT NULL,
    line2           VARCHAR(255),
    city            VARCHAR(100)    NOT NULL DEFAULT 'Doha',
    area            VARCHAR(100),
    country         VARCHAR(80)     NOT NULL DEFAULT 'Qatar',
    postal_code     VARCHAR(20),
    latitude        NUMERIC(9,6),
    longitude       NUMERIC(9,6),
    is_default      BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_addresses_user    ON addresses (user_id);
CREATE INDEX idx_addresses_default ON addresses (user_id, is_default) WHERE is_default = TRUE;

-- Ensure only one default address per user
CREATE UNIQUE INDEX uq_addresses_default ON addresses (user_id) WHERE is_default = TRUE;

-- =============================================================
-- COUPONS
-- =============================================================

CREATE TABLE coupons (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    code                VARCHAR(50)     NOT NULL UNIQUE,
    description         VARCHAR(255),
    discount_type       discount_type   NOT NULL,
    discount_value      NUMERIC(10,2)   NOT NULL CHECK (discount_value > 0),
    min_order_amount    NUMERIC(10,2)   NOT NULL DEFAULT 0,
    max_discount_amount NUMERIC(10,2),
    usage_limit         INT,
    usage_count         INT             NOT NULL DEFAULT 0,
    per_user_limit      INT             NOT NULL DEFAULT 1,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    valid_from          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    valid_until         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_coupon_validity CHECK (valid_until IS NULL OR valid_until > valid_from)
);

CREATE INDEX idx_coupons_code    ON coupons (code);
CREATE INDEX idx_coupons_active  ON coupons (is_active, valid_from, valid_until);

-- =============================================================
-- CARTS
-- =============================================================

CREATE TABLE carts (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID        UNIQUE REFERENCES users (id) ON DELETE CASCADE,
    session_id  VARCHAR(120) UNIQUE,   -- for guest carts
    coupon_id   UUID        REFERENCES coupons (id) ON DELETE SET NULL,
    expires_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_cart_owner CHECK (
        (user_id IS NOT NULL AND session_id IS NULL) OR
        (user_id IS NULL AND session_id IS NOT NULL)
    )
);

CREATE INDEX idx_carts_user     ON carts (user_id);
CREATE INDEX idx_carts_session  ON carts (session_id);

CREATE TABLE cart_items (
    id          UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_id     UUID            NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
    product_id  UUID            NOT NULL REFERENCES products (id) ON DELETE CASCADE,
    quantity    INT             NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price  NUMERIC(10,2)   NOT NULL,    -- price snapshot at add-to-cart time
    added_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (cart_id, product_id)
);

CREATE INDEX idx_cart_items_cart    ON cart_items (cart_id);
CREATE INDEX idx_cart_items_product ON cart_items (product_id);

-- =============================================================
-- ORDERS
-- =============================================================

CREATE TABLE orders (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID            NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    address_id          UUID            NOT NULL REFERENCES addresses (id) ON DELETE RESTRICT,
    coupon_id           UUID            REFERENCES coupons (id) ON DELETE SET NULL,
    order_number        VARCHAR(30)     NOT NULL UNIQUE,
    status              order_status    NOT NULL DEFAULT 'pending',
    payment_method      payment_method  NOT NULL,
    payment_status      payment_status  NOT NULL DEFAULT 'pending',
    payment_reference   VARCHAR(200),
    subtotal            NUMERIC(10,2)   NOT NULL CHECK (subtotal >= 0),
    discount_amount     NUMERIC(10,2)   NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    delivery_fee        NUMERIC(10,2)   NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0),
    total               NUMERIC(10,2)   NOT NULL CHECK (total >= 0),
    notes               TEXT,
    estimated_delivery  TIMESTAMPTZ,
    delivered_at        TIMESTAMPTZ,
    cancelled_at        TIMESTAMPTZ,
    cancellation_reason TEXT,
    address_snapshot    JSONB           NOT NULL,   -- denormalized address at order time
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_user       ON orders (user_id);
CREATE INDEX idx_orders_status     ON orders (status);
CREATE INDEX idx_orders_number     ON orders (order_number);
CREATE INDEX idx_orders_payment    ON orders (payment_status);
CREATE INDEX idx_orders_created    ON orders (created_at DESC);

CREATE TABLE order_items (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID            NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    product_id      UUID            NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    supplier_id     UUID            REFERENCES suppliers (id) ON DELETE SET NULL,
    product_name    VARCHAR(255)    NOT NULL,   -- snapshot
    product_sku     VARCHAR(100),               -- snapshot
    product_image   TEXT,                       -- snapshot
    quantity        INT             NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10,2)   NOT NULL CHECK (unit_price >= 0),
    total_price     NUMERIC(10,2)   NOT NULL CHECK (total_price >= 0),
    is_reviewed     BOOLEAN         NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_order_items_order   ON order_items (order_id);
CREATE INDEX idx_order_items_product ON order_items (product_id);

-- =============================================================
-- REVIEWS
-- =============================================================

CREATE TABLE reviews (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id  UUID        NOT NULL REFERENCES products (id) ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    order_id    UUID        REFERENCES orders (id) ON DELETE SET NULL,
    rating      SMALLINT    NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title       VARCHAR(120),
    body        TEXT,
    images      TEXT[]      NOT NULL DEFAULT '{}',
    is_verified BOOLEAN     NOT NULL DEFAULT FALSE,   -- purchased the product
    is_approved BOOLEAN     NOT NULL DEFAULT TRUE,
    helpful_count INT       NOT NULL DEFAULT 0,
    reply       TEXT,       -- supplier/admin reply
    replied_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (product_id, user_id, order_id)
);

CREATE INDEX idx_reviews_product  ON reviews (product_id);
CREATE INDEX idx_reviews_user     ON reviews (user_id);
CREATE INDEX idx_reviews_rating   ON reviews (product_id, rating);
CREATE INDEX idx_reviews_approved ON reviews (is_approved) WHERE is_approved = TRUE;

-- =============================================================
-- WISHLIST
-- =============================================================

CREATE TABLE wishlist (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    product_id  UUID        NOT NULL REFERENCES products (id) ON DELETE CASCADE,
    added_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, product_id)
);

CREATE INDEX idx_wishlist_user    ON wishlist (user_id);
CREATE INDEX idx_wishlist_product ON wishlist (product_id);

-- =============================================================
-- LOYALTY POINTS
-- =============================================================

CREATE TABLE loyalty_points (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    order_id        UUID        REFERENCES orders (id) ON DELETE SET NULL,
    points_delta    INT         NOT NULL,           -- positive = earned, negative = redeemed
    balance_after   INT         NOT NULL CHECK (balance_after >= 0),
    description     VARCHAR(255),
    expires_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_loyalty_user    ON loyalty_points (user_id);
CREATE INDEX idx_loyalty_order   ON loyalty_points (order_id);
CREATE INDEX idx_loyalty_expires ON loyalty_points (expires_at) WHERE expires_at IS NOT NULL;

-- View: current balance per user
CREATE VIEW loyalty_balances AS
    SELECT user_id, COALESCE(SUM(points_delta), 0) AS balance
    FROM loyalty_points
    WHERE expires_at IS NULL OR expires_at > NOW()
    GROUP BY user_id;

-- =============================================================
-- NOTIFICATIONS
-- =============================================================

CREATE TABLE notifications (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    type        notif_type  NOT NULL,
    title       VARCHAR(200) NOT NULL,
    body        TEXT        NOT NULL,
    data        JSONB       NOT NULL DEFAULT '{}',   -- {order_id, product_id, …}
    is_read     BOOLEAN     NOT NULL DEFAULT FALSE,
    read_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notif_user      ON notifications (user_id);
CREATE INDEX idx_notif_unread    ON notifications (user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notif_created   ON notifications (created_at DESC);
CREATE INDEX idx_notif_type      ON notifications (type);

-- =============================================================
-- TRIGGERS: updated_at auto-maintenance
-- =============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'users', 'categories', 'suppliers', 'products',
        'addresses', 'coupons', 'carts', 'orders', 'reviews'
    ] LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%I_updated_at
             BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
            tbl, tbl
        );
    END LOOP;
END;
$$;

-- =============================================================
-- TRIGGERS: keep product aggregate stats current
-- =============================================================

CREATE OR REPLACE FUNCTION refresh_product_rating()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE products
    SET
        average_rating = (
            SELECT ROUND(AVG(rating)::NUMERIC, 2)
            FROM reviews
            WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)
              AND is_approved = TRUE
        ),
        review_count = (
            SELECT COUNT(*)
            FROM reviews
            WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)
              AND is_approved = TRUE
        )
    WHERE id = COALESCE(NEW.product_id, OLD.product_id);
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_review_stats
AFTER INSERT OR UPDATE OR DELETE ON reviews
FOR EACH ROW EXECUTE FUNCTION refresh_product_rating();

-- =============================================================
-- TRIGGERS: inventory reservation on order placement
-- =============================================================

CREATE OR REPLACE FUNCTION reserve_inventory()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE inventory
    SET reserved = reserved + NEW.quantity
    WHERE product_id = NEW.product_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_reserve_inventory
AFTER INSERT ON order_items
FOR EACH ROW EXECUTE FUNCTION reserve_inventory();

-- =============================================================
-- TRIGGERS: order number generation
-- =============================================================

CREATE SEQUENCE order_seq START 10000;

CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.order_number := 'QC-' || LPAD(nextval('order_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_order_number
BEFORE INSERT ON orders
FOR EACH ROW EXECUTE FUNCTION generate_order_number();

-- =============================================================
-- SEED: root categories
-- =============================================================

INSERT INTO categories (name, slug, sort_order) VALUES
    ('Groceries',        'groceries',    1),
    ('Electronics',      'electronics',  2),
    ('Fashion',          'fashion',      3),
    ('Home & Living',    'home-living',  4),
    ('Sports',           'sports',       5),
    ('Beauty',           'beauty',       6),
    ('Books',            'books',        7),
    ('Toys',             'toys',         8),
    ('Automotive',       'automotive',   9),
    ('Health',           'health',      10),
    ('Garden',           'garden',      11),
    ('Pets',             'pets',        12);
