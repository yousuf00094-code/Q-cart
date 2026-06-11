-- Q Cart — demo seed (exact schema match)
-- Passwords: Admin123! | Customer123! | Supplier123!
-- Coupons:   WELCOME10 (10%) | DEMO20 (20%) | FLAT50 (QAR 50 off)

DO $$
DECLARE
  admin_id         UUID := '00000000-0000-0000-0000-000000000001';
  customer_id      UUID := '00000000-0000-0000-0000-000000000002';
  supplier_user_id UUID := '00000000-0000-0000-0000-000000000003';
  supplier_id      UUID := '00000000-0000-0000-0000-000000000010';

  cat_electronics UUID := '10000000-0000-0000-0000-000000000001';
  cat_clothing    UUID := '10000000-0000-0000-0000-000000000002';
  cat_food        UUID := '10000000-0000-0000-0000-000000000003';
  cat_beauty      UUID := '10000000-0000-0000-0000-000000000004';
  cat_home        UUID := '10000000-0000-0000-0000-000000000005';

  p1 UUID := '20000000-0000-0000-0000-000000000001';
  p2 UUID := '20000000-0000-0000-0000-000000000002';
  p3 UUID := '20000000-0000-0000-0000-000000000003';
  p4 UUID := '20000000-0000-0000-0000-000000000004';
  p5 UUID := '20000000-0000-0000-0000-000000000005';
  p6 UUID := '20000000-0000-0000-0000-000000000006';
  p7 UUID := '20000000-0000-0000-0000-000000000007';
  p8 UUID := '20000000-0000-0000-0000-000000000008';

  addr_id UUID := '30000000-0000-0000-0000-000000000001';
  cart_id UUID := '40000000-0000-0000-0000-000000000001';
  order1  UUID := '50000000-0000-0000-0000-000000000001';
  order2  UUID := '50000000-0000-0000-0000-000000000002';
  order3  UUID := '50000000-0000-0000-0000-000000000003';

  addr_snap JSONB := '{"first_name":"Sara","last_name":"Al-Mansoori","address_line1":"Villa 14, Street 22, Zone 39","city":"Doha","country":"QA"}';
BEGIN

-- ── Users ─────────────────────────────────────────────────────────────────────
INSERT INTO users (id, full_name, email, phone, password_hash, role, is_email_verified, is_active, created_at, updated_at) VALUES
  (admin_id,         'Admin User',       'admin@qcart.qa',    '+97412000001',
   '$2a$12$WD3M4I7igbH6Fc1cr1C2bu/8FWi2pJhlrT9xNRUcSDmh6/aKV9v0i',
   'admin',    TRUE, TRUE, NOW()-INTERVAL '180 days', NOW()),
  (customer_id,      'Sara Al-Mansoori', 'customer@qcart.qa', '+97412000002',
   '$2a$12$YzalTJ//A6roWYvLPIN/ve2pZgYcUlgDDMLhkhgJviKGmgX/rLOrW',
   'customer', TRUE, TRUE, NOW()-INTERVAL '90 days',  NOW()),
  (supplier_user_id, 'Khalid Supplies',  'supplier@qcart.qa', '+97412000003',
   '$2a$12$BGNgMudIaLfPx0wAc1kBBO.2kpnFeWXWq8dVQzFdkONeavSvNcLVa',
   'supplier', TRUE, TRUE, NOW()-INTERVAL '60 days',  NOW())
ON CONFLICT (email) DO NOTHING;

-- ── Supplier ──────────────────────────────────────────────────────────────────
INSERT INTO suppliers (id, user_id, name, email, phone, contact_person, status, rating, created_at, updated_at)
VALUES (
  supplier_id, supplier_user_id,
  'Khalid Tech Supplies LLC', 'supplier@qcart.qa', '+97412000003',
  'Khalid Al-Dosari', 'active', 4.7,
  NOW()-INTERVAL '60 days', NOW()
) ON CONFLICT DO NOTHING;

-- ── Categories ────────────────────────────────────────────────────────────────
INSERT INTO categories (id, name, slug, description, sort_order, is_active, created_at, updated_at) VALUES
  (cat_electronics, 'Electronics',   'electronics',  'Phones, laptops, gadgets',         1, TRUE, NOW(), NOW()),
  (cat_clothing,    'Clothing',       'clothing',     'Men, women and kids fashion',       2, TRUE, NOW(), NOW()),
  (cat_food,        'Food & Grocery', 'food-grocery', 'Fresh produce, snacks, beverages',  3, TRUE, NOW(), NOW()),
  (cat_beauty,      'Beauty & Care',  'beauty-care',  'Skincare, makeup, personal care',   4, TRUE, NOW(), NOW()),
  (cat_home,        'Home & Kitchen', 'home-kitchen', 'Appliances, décor, kitchenware',    5, TRUE, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- ── Products ─────────────────────────────────────────────────────────────────
INSERT INTO products (id, supplier_id, category_id, name, slug, description, price, cost_price, sku, images, is_active, is_featured, created_at, updated_at) VALUES
  (p1, supplier_id, cat_electronics, 'Samsung Galaxy S24 Ultra', 'samsung-galaxy-s24-ultra',
   '200MP camera, AI features, built-in S Pen. 12GB RAM, 256GB.',
   3599.00, 2800.00, 'SAM-S24U-256',
   '["https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=600"]'::jsonb,
   TRUE, TRUE, NOW()-INTERVAL '30 days', NOW()),
  (p2, supplier_id, cat_electronics, 'Apple AirPods Pro (2nd Gen)', 'apple-airpods-pro-2nd-gen',
   'Active Noise Cancellation, Adaptive Transparency. 30h battery.',
   899.00, 620.00, 'APL-AIRPODSPRO2',
   '["https://images.unsplash.com/photo-1606741965509-717f6cfc41d7?w=600"]'::jsonb,
   TRUE, TRUE, NOW()-INTERVAL '25 days', NOW()),
  (p3, supplier_id, cat_electronics, 'Sony WH-1000XM5 Headphones', 'sony-wh-1000xm5',
   'Industry-leading noise cancelling. 30h battery.',
   1299.00, 950.00, 'SNY-WH1000XM5',
   '["https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600"]'::jsonb,
   TRUE, FALSE, NOW()-INTERVAL '15 days', NOW()),
  (p4, supplier_id, cat_clothing, 'Premium Linen Thobe', 'premium-linen-thobe',
   'Traditional Qatari thobe. Breathable linen. Sizes S–XXL.',
   245.00, 140.00, 'CLO-THOBE-LIN-WHT',
   '["https://images.unsplash.com/photo-1621072156002-e2fccdc0b176?w=600"]'::jsonb,
   TRUE, FALSE, NOW()-INTERVAL '20 days', NOW()),
  (p5, supplier_id, cat_food, 'Medjool Dates 1kg Box', 'medjool-dates-1kg',
   'Premium Medjool dates from Jordan. Gift-boxed.',
   89.00, 55.00, 'FOOD-DATES-MED-1KG',
   '["https://images.unsplash.com/photo-1574856344991-aaa31b6f4ce3?w=600"]'::jsonb,
   TRUE, TRUE, NOW()-INTERVAL '5 days', NOW()),
  (p6, supplier_id, cat_beauty, 'Oud Perfume Collection Set', 'oud-perfume-collection-set',
   '3 authentic oud fragrances: Rose, Black, Royal. 50ml each.',
   550.00, 320.00, 'BEA-OUD-SET-3X50',
   '["https://images.unsplash.com/photo-1541643600914-78b084683702?w=600"]'::jsonb,
   TRUE, FALSE, NOW()-INTERVAL '10 days', NOW()),
  (p7, supplier_id, cat_home, 'Arabic Coffee Set (Dallah + 6 cups)', 'arabic-coffee-set-dallah',
   'Handcrafted stainless steel dallah with 6 cups for qahwa.',
   320.00, 190.00, 'HOM-DALLAH-SS-6CUP',
   '["https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600"]'::jsonb,
   TRUE, FALSE, NOW()-INTERVAL '8 days', NOW()),
  (p8, supplier_id, cat_electronics, 'iPad Air 11-inch (M2)', 'apple-ipad-air-m2-11',
   'M2 chip, 11-inch Liquid Retina display, 128GB Wi-Fi 6E.',
   2799.00, 2100.00, 'APL-IPADAIR-M2-128',
   '["https://images.unsplash.com/photo-1585790050230-5dd28404ccb9?w=600"]'::jsonb,
   TRUE, TRUE, NOW()-INTERVAL '3 days', NOW())
ON CONFLICT DO NOTHING;

-- ── Inventory ─────────────────────────────────────────────────────────────────
INSERT INTO inventory (product_id, quantity, reserved, reorder_point, reorder_qty) VALUES
  (p1,48,2,5,20),(p2,120,5,10,30),(p3,65,1,5,20),(p4,200,0,20,50),
  (p5,350,10,30,100),(p6,85,3,10,25),(p7,42,0,5,15),(p8,30,1,5,10)
ON CONFLICT (product_id) DO UPDATE SET quantity=EXCLUDED.quantity, updated_at=NOW();

-- ── Address ───────────────────────────────────────────────────────────────────
INSERT INTO addresses (id, user_id, label, first_name, last_name, phone, address_line1, address_line2, city, state, country, is_default, created_at, updated_at)
VALUES (addr_id, customer_id, 'Home', 'Sara', 'Al-Mansoori', '+97412000002',
  'Villa 14, Street 22, Zone 39', 'Al Sadd Area', 'Doha', 'Ad Dawhah', 'QA',
  TRUE, NOW()-INTERVAL '85 days', NOW())
ON CONFLICT DO NOTHING;

-- ── Cart ─────────────────────────────────────────────────────────────────────
INSERT INTO carts (id, user_id, updated_at)
VALUES (cart_id, customer_id, NOW())
ON CONFLICT DO NOTHING;

INSERT INTO cart_items (cart_id, product_id, quantity, unit_price, added_at, updated_at) VALUES
  (cart_id, p2, 1, 899.00,  NOW(), NOW()),
  (cart_id, p5, 2, 89.00,   NOW(), NOW())
ON CONFLICT DO NOTHING;

-- ── Orders ────────────────────────────────────────────────────────────────────
INSERT INTO orders (id, user_id, address_id, order_number, status, payment_method, payment_status,
                    subtotal, discount_amount, delivery_fee, total, address_snapshot, created_at, updated_at) VALUES
  (order1, customer_id, addr_id, 'QC-841023', 'delivered',
   'qpay', 'paid', 3599.00, 0.00, 0.00, 3599.00, addr_snap,
   NOW()-INTERVAL '14 days', NOW()-INTERVAL '10 days'),
  (order2, customer_id, addr_id, 'QC-849311', 'out_for_delivery',
   'cash_on_delivery', 'pending', 1849.00, 0.00, 0.00, 1849.00, addr_snap,
   NOW()-INTERVAL '2 days', NOW()-INTERVAL '4 hours'),
  (order3, customer_id, addr_id, 'QC-852104', 'pending',
   'cash_on_delivery', 'pending', 498.00, 49.80, 0.00, 448.20, addr_snap,
   NOW()-INTERVAL '10 minutes', NOW()-INTERVAL '10 minutes')
ON CONFLICT DO NOTHING;

INSERT INTO order_items (order_id, product_id, supplier_id, product_name, product_sku, quantity, unit_price, total_price) VALUES
  (order1, p1, supplier_id, 'Samsung Galaxy S24 Ultra',        'SAM-S24U-256',      1, 3599.00, 3599.00),
  (order2, p3, supplier_id, 'Sony WH-1000XM5 Headphones',      'SNY-WH1000XM5',     1, 1299.00, 1299.00),
  (order2, p6, supplier_id, 'Oud Perfume Collection Set',       'BEA-OUD-SET-3X50',  1,  550.00,  550.00),
  (order3, p5, supplier_id, 'Medjool Dates 1kg Box',            'FOOD-DATES-MED-1KG',2,   89.00,  178.00),
  (order3, p7, supplier_id, 'Arabic Coffee Set (Dallah+6cups)', 'HOM-DALLAH-SS-6CUP',1,  320.00,  320.00)
ON CONFLICT DO NOTHING;

-- ── Wishlist ──────────────────────────────────────────────────────────────────
INSERT INTO wishlist (user_id, product_id) VALUES
  (customer_id, p3),
  (customer_id, p4),
  (customer_id, p8)
ON CONFLICT DO NOTHING;

-- ── Coupons ───────────────────────────────────────────────────────────────────
INSERT INTO coupons (code, description, discount_type, discount_value, min_order_amount, usage_limit, is_active, valid_from, valid_until) VALUES
  ('WELCOME10','10% off your first order',    'percentage',10.00,100.00,1000,TRUE,NOW(),NOW()+INTERVAL '30 days'),
  ('DEMO20',   '20% off for demo review',     'percentage',20.00,200.00, 500,TRUE,NOW(),NOW()+INTERVAL '30 days'),
  ('FLAT50',   'QAR 50 off orders over QAR 300','fixed',   50.00,300.00, 200,TRUE,NOW(),NOW()+INTERVAL '30 days')
ON CONFLICT (code) DO UPDATE SET is_active=TRUE, valid_until=NOW()+INTERVAL '30 days', updated_at=NOW();

-- ── Review ────────────────────────────────────────────────────────────────────
INSERT INTO reviews (product_id, user_id, order_id, rating, body, is_verified, is_approved, created_at, updated_at)
VALUES (p1, customer_id, order1, 5,
  'Absolutely amazing phone. The camera is incredible and the S Pen makes it perfect for work. Fast delivery too!',
  TRUE, TRUE, NOW()-INTERVAL '9 days', NOW())
ON CONFLICT DO NOTHING;

-- ── Loyalty points ────────────────────────────────────────────────────────────
INSERT INTO loyalty_points (user_id, order_id, points_delta, balance_after, description, created_at) VALUES
  (customer_id, order1, 3599, 3599, 'Earned – Order QC-841023', NOW()-INTERVAL '10 days'),
  (customer_id, order2, 1849, 5448, 'Earned – Order QC-849311', NOW()-INTERVAL '4 hours')
ON CONFLICT DO NOTHING;

-- ── Supplier payouts ──────────────────────────────────────────────────────────
INSERT INTO supplier_payouts (supplier_id, period_from, period_to, gross_amount, commission_amount, net_amount, status, paid_at, bank_reference, created_at, updated_at) VALUES
  (supplier_id, DATE_TRUNC('month',NOW()-INTERVAL '1 month'), DATE_TRUNC('month',NOW())-INTERVAL '1 second',
   18450.00, 1845.00, 16605.00, 'paid', NOW()-INTERVAL '5 days', 'QCPAY-2026-MAY-001', NOW()-INTERVAL '35 days', NOW()),
  (supplier_id, DATE_TRUNC('month',NOW()), DATE_TRUNC('month',NOW())+INTERVAL '1 month'-INTERVAL '1 second',
   5448.00, 544.80, 4903.20, 'pending', NULL, NULL, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- ── Supplier risk score ───────────────────────────────────────────────────────
-- Use a plain INSERT ignoring conflict (no ambiguous column reference in DO UPDATE)
INSERT INTO supplier_risk_scores (supplier_id, score, risk_level, factors, computed_at)
VALUES ('00000000-0000-0000-0000-000000000010'::uuid, 8, 'minimal', '[]'::jsonb, NOW())
ON CONFLICT DO NOTHING;

RAISE NOTICE '==============================================';
RAISE NOTICE 'Q Cart demo seed complete.';
RAISE NOTICE 'Admin:    admin@qcart.qa    / Admin123!';
RAISE NOTICE 'Customer: customer@qcart.qa / Customer123!';
RAISE NOTICE 'Supplier: supplier@qcart.qa / Supplier123!';
RAISE NOTICE 'Coupons:  WELCOME10 | DEMO20 | FLAT50';
RAISE NOTICE '==============================================';
END $$;
