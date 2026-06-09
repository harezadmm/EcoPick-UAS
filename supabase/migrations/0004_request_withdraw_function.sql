-- User-facing withdrawal REQUEST: records a pending greencoin_transactions
-- row WITHOUT deducting the balance. An admin later approves (deducts balance,
-- marks completed) or rejects (balance untouched).
--
-- SECURITY DEFINER bypasses the admin-only RLS on greencoin_transactions while
-- still verifying the caller owns the account. Rupiah is computed server-side
-- from a trusted rate, never trusted from the client.
CREATE OR REPLACE FUNCTION public.request_withdraw(
  p_wallet_provider text,
  p_account_number text,
  p_account_name text,
  p_amount_gc integer
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_balance integer;
  v_txn_id uuid;
  v_rate integer := 100;
  v_amount_rupiah bigint;
  v_min_rupiah integer := 10000;
  v_max_rupiah integer := 2000000000;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Tidak terautentikasi';
  END IF;
  IF p_amount_gc <= 0 THEN
    RAISE EXCEPTION 'Jumlah penarikan harus lebih dari 0';
  END IF;

  v_amount_rupiah := p_amount_gc::bigint * v_rate;
  IF v_amount_rupiah < v_min_rupiah THEN
    RAISE EXCEPTION 'Minimal penarikan Rp %', v_min_rupiah;
  END IF;
  IF v_amount_rupiah > v_max_rupiah THEN
    RAISE EXCEPTION 'Maksimal penarikan Rp % per transaksi', v_max_rupiah;
  END IF;

  SELECT green_coin_balance INTO v_balance
  FROM profiles
  WHERE id = v_user_id;

  IF v_balance IS NULL THEN
    RAISE EXCEPTION 'Profil tidak ditemukan';
  END IF;
  IF p_amount_gc > v_balance THEN
    RAISE EXCEPTION 'Saldo tidak cukup. Saldo Anda % GC', v_balance;
  END IF;

  INSERT INTO greencoin_transactions (
    user_id, source_type, transaction_type,
    amount_gc, amount_rupiah, status, description
  ) VALUES (
    v_user_id, 'withdraw', 'withdraw',
    -p_amount_gc, -v_amount_rupiah::integer, 'pending',
    p_wallet_provider || ' • ' || p_account_number ||
      COALESCE(' • ' || NULLIF(p_account_name, ''), '')
  )
  RETURNING id INTO v_txn_id;

  RETURN v_txn_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.request_withdraw(text, text, text, integer) TO authenticated;
