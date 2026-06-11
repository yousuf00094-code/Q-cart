-- Q Cart — Supplier APIs: shipments, payouts, risk scores
-- Migration 002 — idempotent; run after 001_initial_schema.sql

-- ── Enums ─────────────────────────────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE shipment_status AS ENUM (
    'pending','picked_up','in_transit','out_for_delivery','delivered','failed','returned'
  );
  EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE payout_status AS ENUM (
    'pending','processing','paid','failed','on_hold'
  );
  EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ── Shipments ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS shipments (
  id                 UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id           UUID            NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  supplier_id        UUID            REFERENCES suppliers(id) ON DELETE SET NULL,
  carrier            VARCHAR(100),
  tracking_number    VARCHAR(200),
  status             shipment_status NOT NULL DEFAULT 'pending',
  shipped_at         TIMESTAMPTZ,
  estimated_delivery TIMESTAMPTZ,
  delivered_at       TIMESTAMPTZ,
  notes              TEXT,
  created_at         TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shipments_order_id    ON shipments (order_id);
CREATE INDEX IF NOT EXISTS idx_shipments_supplier_id ON shipments (supplier_id);
CREATE INDEX IF NOT EXISTS idx_shipments_status      ON shipments (status);
CREATE INDEX IF NOT EXISTS idx_shipments_created_at  ON shipments (created_at DESC);

-- ── Shipment Events ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS shipment_events (
  id          UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  shipment_id UUID         NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
  status      VARCHAR(100) NOT NULL,
  location    VARCHAR(200),
  description TEXT,
  occurred_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shipment_events_shipment_id ON shipment_events (shipment_id);
CREATE INDEX IF NOT EXISTS idx_shipment_events_occurred_at ON shipment_events (shipment_id, occurred_at ASC);

-- ── Supplier Payouts ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS supplier_payouts (
  id                UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  supplier_id       UUID          NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
  period_from       TIMESTAMPTZ   NOT NULL,
  period_to         TIMESTAMPTZ   NOT NULL,
  gross_amount      NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (gross_amount >= 0),
  commission_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (commission_amount >= 0),
  net_amount        NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (net_amount >= 0),
  status            payout_status NOT NULL DEFAULT 'pending',
  paid_at           TIMESTAMPTZ,
  bank_reference    VARCHAR(200),
  notes             TEXT,
  created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_supplier_payouts_supplier_id ON supplier_payouts (supplier_id);
CREATE INDEX IF NOT EXISTS idx_supplier_payouts_status      ON supplier_payouts (status);
CREATE INDEX IF NOT EXISTS idx_supplier_payouts_period      ON supplier_payouts (supplier_id, period_from DESC);

-- ── Supplier Payout Items ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS supplier_payout_items (
  id           UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  payout_id    UUID          NOT NULL REFERENCES supplier_payouts(id) ON DELETE CASCADE,
  order_id     UUID          REFERENCES orders(id) ON DELETE SET NULL,
  order_number VARCHAR(30),
  amount       NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  commission   NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (commission >= 0),
  net          NUMERIC(12,2) NOT NULL CHECK (net >= 0),
  created_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payout_items_payout_id ON supplier_payout_items (payout_id);

-- ── Supplier Risk Scores ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS supplier_risk_scores (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  supplier_id UUID        NOT NULL UNIQUE REFERENCES suppliers(id) ON DELETE CASCADE,
  score       SMALLINT    NOT NULL DEFAULT 0 CHECK (score BETWEEN 0 AND 100),
  risk_level  VARCHAR(20) NOT NULL DEFAULT 'minimal',
  factors     JSONB       NOT NULL DEFAULT '[]',
  computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_risk_scores_supplier_id ON supplier_risk_scores (supplier_id);
CREATE INDEX IF NOT EXISTS idx_risk_scores_risk_level  ON supplier_risk_scores (risk_level);

-- ── Triggers ──────────────────────────────────────────────────────────────────

DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['shipments','supplier_payouts','supplier_risk_scores'] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger WHERE tgname = 'trg_' || t || '_updated_at'
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
