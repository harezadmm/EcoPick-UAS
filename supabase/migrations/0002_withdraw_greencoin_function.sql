-- Atomic withdrawal: validates balance, creates withdraw_request,
-- records a greencoin transaction, and deducts the user's balance.
-- SECURITY DEFINER lets it bypass the admin-only RLS on greencoin_transactions
-- while still verifying the caller owns the account.
CREATE OR REPLACE FUNCTION public.withdraw_greencoin(
  p_wallet_provider text,
  p_account_number text,
  p_amount_gc integer,
  p_amount_rupiah integer
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_balance integer;
  v_request_id uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Tidak terautentikasi';
  END IF;

  IF p_amount_gc <= 0 THEN
    RAISE EXCEPTION 'Jumlah penarikan harus lebih dari 0';
  END IF;

  -- Lock the profile row to prevent concurrent double-spend
  SELECT green_coin_balance INTO v_balance
  FROM profiles
  WHERE id = v_user_id
  FOR UPDATE;

  IF v_balance IS NULL THEN
    RAISE EXCEPTION 'Profil tidak ditemukan';
  END IF;

  IF p_amount_gc > v_balance THEN
    RAISE EXCEPTION 'Saldo tidak cukup. Saldo Anda % GC', v_balance;
  END IF;

  -- 1. Create the withdraw request (status process)
  INSERT INTO withdraw_requests (
    user_id, wallet_provider, wallet_account_number,
    amount_gc, amount_rupiah, status
  ) VALUES (
    v_user_id, p_wallet_provider, p_account_number,
    p_amount_gc, p_amount_rupiah, 'process'
  )
  RETURNING id INTO v_request_id;

  -- 2. Record the greencoin transaction (negative = outflow)
  INSERT INTO greencoin_transactions (
    user_id, source_type, source_id, transaction_type,
    amount_gc, amount_rupiah, status, description
  ) VALUES (
    v_user_id, 'withdraw', v_request_id, 'withdraw',
    -p_amount_gc, -p_amount_rupiah, 'process',
    'Penarikan ke ' || p_wallet_provider || ' ' || p_account_number
  );

  -- 3. Deduct the balance immediately
  UPDATE profiles
  SET green_coin_balance = green_coin_balance - p_amount_gc,
      updated_at = now()
  WHERE id = v_user_id;

  RETURN v_request_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.withdraw_greencoin(text, text, integer, integer) TO authenticated;
