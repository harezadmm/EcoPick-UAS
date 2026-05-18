-- Default waste categories
insert into public.waste_categories (name, green_coin_per_kg, is_active) values
  ('Besi', 400, true),
  ('Plastik', 200, true),
  ('Elektronik', 500, true),
  ('Kaca', 300, true),
  ('Kardus', 150, true),
  ('Kertas', 150, true),
  ('Logam', 400, true)
on conflict (name) do nothing;

-- Sample marketplace products
insert into public.marketplace_products (name, description, price_gc, stock, is_active) values
  ('Beras 5 kg', 'Beras premium siap masak', 2500, 12, true),
  ('Minyak Goreng 2L', 'Minyak goreng bermerk', 1800, 8, true),
  ('Detergen 1 kg', 'Detergen pembersih pakaian', 900, 24, true),
  ('Sabun Cuci Piring', 'Sabun cuci anti-bakteri', 600, 30, true);
