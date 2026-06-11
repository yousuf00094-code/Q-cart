-- Q Cart — development seed data for supplier APIs
-- Requires: 001_initial_schema.sql + 002_supplier_apis.sql applied first.
-- Idempotent: INSERT ... ON CONFLICT DO NOTHING / DO UPDATE.

DO $$
DECLARE
  sup1_id    UUID;
  sup2_id    UUID;
  order1_id  UUID;
  ship1_id   UUID   := 'a1000000-0000-0000-0000-000000000001';
  ship2_id   UUID   := 'a1000000-0000-0000-0000-000000000002';
  payout1_id UUID   := 'b1000000-0000-0000-0000-000000000001';
  payout2_id UUID   := 'b1000000-0000-0000-0000-000000000002';
  payout3_id UUID   := 'b1000000-0000-0000-0000-000000000003';
BEGIN
  -- Resolve active suppliers
  SELECT id INTO sup1_id FROM suppliers WHERE status = 'active' ORDER BY created_at LIMIT 1;
  SELECT id INTO sup2_id FROM suppliers WHERE status = 'active' ORDER BY created_at LIMIT 1 OFFSET 1;

  IF sup1_id IS NULL THEN
    RAISE NOTICE 'No active suppliers found — skipping supplier API seed data.';
    RETURN;
  END IF;

  -- ── Shipments ───────────────────────────────────────────────────────────────

  SELECT o.id INTO order1_id
  FROM orders o
  WHERE o.status IN ('confirmed', 'processing', 'packed')
  ORDER BY o.created_at DESC
  LIMIT 1;

  IF order1_id IS NOT NULL THEN
    INSERT INTO shipments (id, order_id, supplier_id, carrier, tracking_number, status, shipped_at, estimated_delivery)
    VALUES (
      ship1_id, order1_id, sup1_id,
      'Aramex', 'ARMS-QA-4821993',
      'in_transit',
      NOW() - INTERVAL '2 days',
      NOW() + INTERVAL '1 day'
    ) ON CONFLICT DO NOTHING;

    INSERT INTO shipment_events (shipment_id, status, location, description, occurred_at) VALUES
      (ship1_id, 'pending',    'Supplier Warehouse, Industrial Area, Doha', 'Order received and queued for packing',      NOW() - INTERVAL '3 days'),
      (ship1_id, 'picked_up',  'Supplier Warehouse, Industrial Area, Doha', 'Parcel collected by Aramex courier',         NOW() - INTERVAL '2 days'),
      (ship1_id, 'in_transit', 'Aramex Doha Sorting Hub',                   'Parcel sorted and loaded onto delivery van', NOW() - INTERVAL '1 day')
    ON CONFLICT DO NOTHING;
  END IF;

  -- A delivered shipment (for history)
  SELECT o.id INTO order1_id
  FROM orders o
  WHERE o.status = 'delivered'
  ORDER BY o.created_at DESC
  LIMIT 1;

  IF order1_id IS NOT NULL THEN
    INSERT INTO shipments (id, order_id, supplier_id, carrier, tracking_number, status, shipped_at, estimated_delivery, delivered_at)
    VALUES (
      ship2_id, order1_id, sup1_id,
      'Qatar Post', 'QP-20240601-7743',
      'delivered',
      NOW() - INTERVAL '10 days',
      NOW() - INTERVAL '7 days',
      NOW() - INTERVAL '7 days'
    ) ON CONFLICT DO NOTHING;

    INSERT INTO shipment_events (shipment_id, status, location, description, occurred_at) VALUES
      (ship2_id, 'pending',           'Supplier Warehouse, West Bay',     'Awaiting carrier pickup',              NOW() - INTERVAL '11 days'),
      (ship2_id, 'picked_up',         'Supplier Warehouse, West Bay',     'Collected by Qatar Post',              NOW() - INTERVAL '10 days'),
      (ship2_id, 'in_transit',        'Qatar Post Sorting Center, Doha',  'In transit',                          NOW() - INTERVAL '9 days'),
      (ship2_id, 'out_for_delivery',  'Qatar Post, Al Rayyan Branch',     'Out for delivery to customer address', NOW() - INTERVAL '7 days' + INTERVAL '2 hours'),
      (ship2_id, 'delivered',         'Customer Address, Al Rayyan',      'Delivered — signed by recipient',     NOW() - INTERVAL '7 days' + INTERVAL '6 hours')
    ON CONFLICT DO NOTHING;
  END IF;

  -- ── Payouts — Supplier 1 ────────────────────────────────────────────────────

  -- Previous month — paid
  INSERT INTO supplier_payouts (
    id, supplier_id,
    period_from, period_to,
    gross_amount, commission_amount, net_amount,
    status, paid_at, bank_reference
  ) VALUES (
    payout1_id, sup1_id,
    DATE_TRUNC('month', NOW() - INTERVAL '1 month'),
    DATE_TRUNC('month', NOW()) - INTERVAL '1 second',
    18450.00, 1845.00, 16605.00,
    'paid',
    NOW() - INTERVAL '5 days',
    'QCPAY-2024-MAY-001'
  ) ON CONFLICT DO NOTHING;

  -- Two months ago — paid
  INSERT INTO supplier_payouts (
    id, supplier_id,
    period_from, period_to,
    gross_amount, commission_amount, net_amount,
    status, paid_at, bank_reference
  ) VALUES (
    payout2_id, sup1_id,
    DATE_TRUNC('month', NOW() - INTERVAL '2 months'),
    DATE_TRUNC('month', NOW() - INTERVAL '1 month') - INTERVAL '1 second',
    14200.00, 1420.00, 12780.00,
    'paid',
    NOW() - INTERVAL '35 days',
    'QCPAY-2024-APR-001'
  ) ON CONFLICT DO NOTHING;

  -- Current period — pending
  INSERT INTO supplier_payouts (
    id, supplier_id,
    period_from, period_to,
    gross_amount, commission_amount, net_amount,
    status
  ) VALUES (
    payout3_id, sup1_id,
    DATE_TRUNC('month', NOW()),
    DATE_TRUNC('month', NOW()) + INTERVAL '1 month' - INTERVAL '1 second',
    5200.00, 520.00, 4680.00,
    'pending'
  ) ON CONFLICT DO NOTHING;

  -- Payout line items for payout1
  INSERT INTO supplier_payout_items (payout_id, order_number, amount, commission, net) VALUES
    (payout1_id, 'QC-100023', 2450.00, 245.00, 2205.00),
    (payout1_id, 'QC-100019', 1200.00, 120.00, 1080.00),
    (payout1_id, 'QC-100017', 3800.00, 380.00, 3420.00),
    (payout1_id, 'QC-100011', 5100.00, 510.00, 4590.00),
    (payout1_id, 'QC-100008', 5900.00, 590.00, 5310.00)
  ON CONFLICT DO NOTHING;

  -- ── Risk Scores ─────────────────────────────────────────────────────────────

  INSERT INTO supplier_risk_scores (supplier_id, score, risk_level, factors, computed_at)
  VALUES (
    sup1_id, 12, 'minimal', '[]'::jsonb, NOW()
  ) ON CONFLICT (supplier_id) DO UPDATE
    SET score = EXCLUDED.score,
        risk_level = EXCLUDED.risk_level,
        factors = EXCLUDED.factors,
        computed_at = EXCLUDED.computed_at,
        updated_at = NOW();

  IF sup2_id IS NOT NULL THEN
    INSERT INTO supplier_risk_scores (supplier_id, score, risk_level, factors, computed_at)
    VALUES (
      sup2_id,
      45,
      'medium',
      '[
        {"label": "Elevated return rate (3.5%)", "actual": 3.5, "target": 3.0, "severity": "warning"},
        {"label": "Late shipments (88.5% on-time)", "actual": 88.5, "target": 95.0, "severity": "warning"}
      ]'::jsonb,
      NOW()
    ) ON CONFLICT (supplier_id) DO UPDATE
      SET score = EXCLUDED.score,
          risk_level = EXCLUDED.risk_level,
          factors = EXCLUDED.factors,
          computed_at = EXCLUDED.computed_at,
          updated_at = NOW();
  END IF;

END $$;
