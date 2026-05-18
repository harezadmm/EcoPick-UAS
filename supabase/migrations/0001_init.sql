-- EcoPoin initial schema
-- Run in Supabase SQL editor or via supabase CLI

create extension if not exists "pgcrypto";

-- profiles table linked to auth.users
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  phone text,
  role text not null default 'user' check (role in ('user', 'admin')),
  green_coin_balance integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists profiles_email_idx on public.profiles(email);
create index if not exists profiles_role_idx on public.profiles(role);

-- waste_categories
create table if not exists public.waste_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  green_coin_per_kg integer not null check (green_coin_per_kg >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ecopick_requests
create table if not exists public.ecopick_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_id uuid not null references public.waste_categories(id),
  estimated_weight_kg numeric(10, 2) not null check (estimated_weight_kg > 0),
  estimated_green_coin integer not null default 0,
  pickup_address text not null,
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  notes text,
  status text not null default 'pending'
    check (status in ('pending', 'process', 'completed', 'rejected')),
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ecopick_user_idx on public.ecopick_requests(user_id);
create index if not exists ecopick_status_idx on public.ecopick_requests(status);

-- ecodrop_requests
create table if not exists public.ecodrop_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_id uuid not null references public.waste_categories(id),
  estimated_weight_kg numeric(10, 2) not null check (estimated_weight_kg > 0),
  estimated_green_coin integer not null default 0,
  bank_sampah_location text not null default 'Bank Sampah Induk Surabaya',
  notes text,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'completed', 'rejected')),
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ecodrop_user_idx on public.ecodrop_requests(user_id);
create index if not exists ecodrop_status_idx on public.ecodrop_requests(status);

-- greencoin_transactions (ledger)
create table if not exists public.greencoin_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  source_type text not null
    check (source_type in ('ecopick','ecodrop','withdraw','marketplace','adjustment')),
  source_id uuid,
  transaction_type text not null
    check (transaction_type in ('earn','withdraw','exchange','refund','adjustment')),
  amount_gc integer not null,
  amount_rupiah integer,
  status text not null default 'completed'
    check (status in ('pending','process','completed','rejected')),
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists greencoin_user_idx on public.greencoin_transactions(user_id);
create index if not exists greencoin_status_idx on public.greencoin_transactions(status);

-- withdraw_requests
create table if not exists public.withdraw_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  wallet_provider text not null check (wallet_provider in ('DANA','GoPay','OVO','ShopeePay')),
  wallet_account_number text not null,
  amount_gc integer not null check (amount_gc > 0),
  amount_rupiah integer not null check (amount_rupiah >= 10000),
  status text not null default 'process'
    check (status in ('process','completed','rejected')),
  admin_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists withdraw_status_idx on public.withdraw_requests(status);

-- marketplace_products
create table if not exists public.marketplace_products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  image_url text,
  price_gc integer not null check (price_gc > 0),
  stock integer not null default 0 check (stock >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- marketplace_orders
create table if not exists public.marketplace_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.marketplace_products(id),
  quantity integer not null default 1 check (quantity > 0),
  total_price_gc integer not null,
  status text not null default 'pending'
    check (status in ('pending','process','completed','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists marketplace_orders_user_idx on public.marketplace_orders(user_id);
create index if not exists marketplace_orders_status_idx on public.marketplace_orders(status);

-- platform_logs
create table if not exists public.platform_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb,
  created_at timestamptz not null default now()
);

-- updated_at trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array[
    'profiles','waste_categories','ecopick_requests','ecodrop_requests',
    'greencoin_transactions','withdraw_requests','marketplace_products','marketplace_orders'
  ] loop
    execute format(
      'drop trigger if exists trg_%1$s_updated on public.%1$s;
       create trigger trg_%1$s_updated before update on public.%1$s
       for each row execute function public.set_updated_at();', t
    );
  end loop;
end $$;

-- Auto-create profile on auth user signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, full_name, email, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.email,
    new.raw_user_meta_data->>'phone',
    'user'
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Atomic balance update RPC
create or replace function public.adjust_balance(
  p_user_id uuid,
  p_amount integer,
  p_source_type text,
  p_source_id uuid,
  p_transaction_type text,
  p_description text default null
) returns void language plpgsql security definer as $$
begin
  update public.profiles
     set green_coin_balance = green_coin_balance + p_amount,
         updated_at = now()
   where id = p_user_id;

  if (select green_coin_balance from public.profiles where id = p_user_id) < 0 then
    raise exception 'Insufficient GreenCoin balance';
  end if;

  insert into public.greencoin_transactions
    (user_id, source_type, source_id, transaction_type, amount_gc, status, description)
  values
    (p_user_id, p_source_type, p_source_id, p_transaction_type, p_amount, 'completed', p_description);
end $$;
