-- RLS policies for EcoPoin
-- Run after the initial migration

alter table public.profiles enable row level security;
alter table public.waste_categories enable row level security;
alter table public.ecopick_requests enable row level security;
alter table public.ecodrop_requests enable row level security;
alter table public.greencoin_transactions enable row level security;
alter table public.withdraw_requests enable row level security;
alter table public.marketplace_products enable row level security;
alter table public.marketplace_orders enable row level security;
alter table public.platform_logs enable row level security;

-- Helper: is_admin()
create or replace function public.is_admin(uid uuid)
returns boolean language sql stable as $$
  select exists (select 1 from public.profiles where id = uid and role = 'admin');
$$;

-- profiles
drop policy if exists profiles_select_self_or_admin on public.profiles;
create policy profiles_select_self_or_admin on public.profiles
  for select using (id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
  for update using (id = auth.uid())
  with check (id = auth.uid() and role = (select role from public.profiles where id = auth.uid()));

drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles
  for update using (public.is_admin(auth.uid()));

-- waste_categories
drop policy if exists wc_read on public.waste_categories;
create policy wc_read on public.waste_categories for select using (true);

drop policy if exists wc_admin_write on public.waste_categories;
create policy wc_admin_write on public.waste_categories
  for all using (public.is_admin(auth.uid())) with check (public.is_admin(auth.uid()));

-- ecopick_requests
drop policy if exists ecopick_select on public.ecopick_requests;
create policy ecopick_select on public.ecopick_requests
  for select using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists ecopick_insert_self on public.ecopick_requests;
create policy ecopick_insert_self on public.ecopick_requests
  for insert with check (user_id = auth.uid());

drop policy if exists ecopick_admin_update on public.ecopick_requests;
create policy ecopick_admin_update on public.ecopick_requests
  for update using (public.is_admin(auth.uid()));

-- ecodrop_requests
drop policy if exists ecodrop_select on public.ecodrop_requests;
create policy ecodrop_select on public.ecodrop_requests
  for select using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists ecodrop_insert_self on public.ecodrop_requests;
create policy ecodrop_insert_self on public.ecodrop_requests
  for insert with check (user_id = auth.uid());

drop policy if exists ecodrop_admin_update on public.ecodrop_requests;
create policy ecodrop_admin_update on public.ecodrop_requests
  for update using (public.is_admin(auth.uid()));

-- greencoin_transactions
drop policy if exists gc_select on public.greencoin_transactions;
create policy gc_select on public.greencoin_transactions
  for select using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists gc_admin_write on public.greencoin_transactions;
create policy gc_admin_write on public.greencoin_transactions
  for all using (public.is_admin(auth.uid())) with check (public.is_admin(auth.uid()));

-- withdraw_requests
drop policy if exists wd_select on public.withdraw_requests;
create policy wd_select on public.withdraw_requests
  for select using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists wd_insert_self on public.withdraw_requests;
create policy wd_insert_self on public.withdraw_requests
  for insert with check (user_id = auth.uid());

drop policy if exists wd_admin_update on public.withdraw_requests;
create policy wd_admin_update on public.withdraw_requests
  for update using (public.is_admin(auth.uid()));

-- marketplace_products
drop policy if exists mp_read_active on public.marketplace_products;
create policy mp_read_active on public.marketplace_products
  for select using (is_active = true or public.is_admin(auth.uid()));

drop policy if exists mp_admin_write on public.marketplace_products;
create policy mp_admin_write on public.marketplace_products
  for all using (public.is_admin(auth.uid())) with check (public.is_admin(auth.uid()));

-- marketplace_orders
drop policy if exists mo_select on public.marketplace_orders;
create policy mo_select on public.marketplace_orders
  for select using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists mo_insert_self on public.marketplace_orders;
create policy mo_insert_self on public.marketplace_orders
  for insert with check (user_id = auth.uid());

drop policy if exists mo_admin_update on public.marketplace_orders;
create policy mo_admin_update on public.marketplace_orders
  for update using (public.is_admin(auth.uid()));

-- platform_logs (admin only read; writes by RPC)
drop policy if exists pl_admin_select on public.platform_logs;
create policy pl_admin_select on public.platform_logs
  for select using (public.is_admin(auth.uid()));
