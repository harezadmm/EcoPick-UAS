-- Atomic marketplace purchase. RLS makes marketplace_products admin-only for
-- writes, so a user's stock UPDATE silently fails — this SECURITY DEFINER
-- function decrements stock, deducts balance, and records the order/transaction
-- atomically while verifying the caller owns the account.
CREATE OR REPLACE FUNCTION public.purchase_product(
  p_product_id uuid,
  p_quantity integer
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_stock integer;
  v_active boolean;
  v_price integer;
  v_name text;
  v_total integer;
  v_balance integer;
  v_order_id uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Tidak terautentikasi';
  END IF;
  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Jumlah harus lebih dari 0';
  END IF;

  SELECT stock, is_active, price_gc, name
    INTO v_stock, v_active, v_price, v_name
  FROM marketplace_products
  WHERE id = p_product_id
  FOR UPDATE;

  IF v_stock IS NULL THEN
    RAISE EXCEPTION 'Produk tidak ditemukan';
  END IF;
  IF NOT v_active THEN
    RAISE EXCEPTION 'Produk ini sudah tidak aktif';
  END IF;
  IF v_stock < p_quantity THEN
    RAISE EXCEPTION 'Stok produk tidak mencukupi';
  END IF;

  v_total := v_price * p_quantity;

  SELECT green_coin_balance INTO v_balance
  FROM profiles
  WHERE id = v_user_id
  FOR UPDATE;

  IF v_balance IS NULL THEN
    RAISE EXCEPTION 'Profil tidak ditemukan';
  END IF;
  IF v_balance < v_total THEN
    RAISE EXCEPTION 'Saldo GreenCoin tidak mencukupi';
  END IF;

  INSERT INTO marketplace_orders (
    user_id, product_id, quantity, total_price_gc, status
  ) VALUES (
    v_user_id, p_product_id, p_quantity, v_total, 'completed'
  )
  RETURNING id INTO v_order_id;

  INSERT INTO greencoin_transactions (
    user_id, source_type, source_id, transaction_type,
    amount_gc, status, description
  ) VALUES (
    v_user_id, 'marketplace', v_order_id, 'exchange',
    -v_total, 'completed', 'Tukar ' || v_name || ' x ' || p_quantity
  );

  UPDATE profiles
  SET green_coin_balance = green_coin_balance - v_total,
      updated_at = now()
  WHERE id = v_user_id;

  UPDATE marketplace_products
  SET stock = stock - p_quantity,
      updated_at = now()
  WHERE id = p_product_id;

  RETURN v_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.purchase_product(uuid, integer) TO authenticated;
