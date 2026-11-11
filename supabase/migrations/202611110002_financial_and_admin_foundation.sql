-- CRYSTAL INVESTMENTS: backend foundation for investor finance and administration.
-- Apply after 202611110001_initial_investor_profiles.sql.
-- This migration creates records and access controls only. It does not move money,
-- initiate payments, approve investments, or grant any user an administrator role.

create extension if not exists pgcrypto;

create table if not exists public.admin_memberships (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('Supa Admin', 'Junior Admin')),
  status text not null default 'Active' check (status in ('Active', 'Suspended')),
  appointed_by uuid references auth.users(id),
  appointed_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.crystal_is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_memberships m
    where m.user_id = (select auth.uid())
      and m.status = 'Active'
  );
$$;

create or replace function public.crystal_is_supa_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_memberships m
    where m.user_id = (select auth.uid())
      and m.role = 'Supa Admin'
      and m.status = 'Active'
  );
$$;

revoke all on function public.crystal_is_admin() from public, anon;
revoke all on function public.crystal_is_supa_admin() from public, anon;
grant execute on function public.crystal_is_admin() to authenticated;
grant execute on function public.crystal_is_supa_admin() to authenticated;

create table if not exists public.investment_opportunities (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  division text not null,
  summary text not null default '',
  description text not null default '',
  currency text not null check (currency in ('KES','USD','GBP')),
  minimum_contribution numeric(20,2),
  status text not null default 'Draft'
    check (status in ('Draft','Under Review','Active','Paused','Closed','Archived')),
  terms_version text,
  risk_disclosure text not null default '',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.deposit_requests (
  id uuid primary key default gen_random_uuid(),
  investor_id uuid not null references auth.users(id) on delete restrict,
  amount numeric(20,2) not null check (amount > 0),
  currency text not null check (currency in ('KES','USD','GBP')),
  payment_method text,
  provider_reference text,
  status text not null default 'Submitted'
    check (status in ('Submitted','Under Review','Approved','Rejected','Cancelled','Reconciled')),
  investor_note text,
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.withdrawal_requests (
  id uuid primary key default gen_random_uuid(),
  investor_id uuid not null references auth.users(id) on delete restrict,
  amount numeric(20,2) not null check (amount > 0),
  currency text not null check (currency in ('KES','USD','GBP')),
  destination_details jsonb not null default '{}'::jsonb,
  status text not null default 'Submitted'
    check (status in ('Submitted','Under Review','Approved','Rejected','Processing','Paid','Cancelled')),
  investor_note text,
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.investment_allocations (
  id uuid primary key default gen_random_uuid(),
  investor_id uuid not null references auth.users(id) on delete restrict,
  opportunity_id uuid not null references public.investment_opportunities(id) on delete restrict,
  contribution_amount numeric(20,2) not null check (contribution_amount > 0),
  currency text not null check (currency in ('KES','USD','GBP')),
  economic_interest numeric(20,8),
  status text not null default 'Pending'
    check (status in ('Pending','Approved','Active','Completed','Suspended','Cancelled')),
  approved_by uuid references auth.users(id),
  activated_at timestamptz,
  terms_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Append-only investor ledger. Amounts remain in their original currency.
create table if not exists public.investor_ledger_entries (
  id uuid primary key default gen_random_uuid(),
  investor_id uuid not null references auth.users(id) on delete restrict,
  allocation_id uuid references public.investment_allocations(id) on delete restrict,
  source_type text not null
    check (source_type in ('Deposit','Withdrawal','Allocation','Distribution','Fee','Adjustment','Reversal')),
  source_id uuid,
  entry_type text not null check (entry_type in ('Credit','Debit')),
  amount numeric(20,2) not null check (amount > 0),
  currency text not null check (currency in ('KES','USD','GBP')),
  effective_at timestamptz not null default now(),
  description text not null default '',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.investment_distributions (
  id uuid primary key default gen_random_uuid(),
  allocation_id uuid not null references public.investment_allocations(id) on delete restrict,
  investor_id uuid not null references auth.users(id) on delete restrict,
  amount numeric(20,2) not null check (amount >= 0),
  currency text not null check (currency in ('KES','USD','GBP')),
  distribution_date date not null,
  status text not null default 'Draft'
    check (status in ('Draft','Approved','Paid','Cancelled')),
  approved_by uuid references auth.users(id),
  paid_at timestamptz,
  description text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.investor_documents (
  id uuid primary key default gen_random_uuid(),
  investor_id uuid not null references auth.users(id) on delete cascade,
  document_type text not null,
  storage_path text not null,
  status text not null default 'Submitted'
    check (status in ('Submitted','Under Review','Accepted','Rejected','Expired')),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id),
  action text not null,
  entity_type text not null,
  entity_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.platform_settings (
  setting_key text primary key,
  setting_value jsonb not null default '{}'::jsonb,
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

-- Enable RLS on every application table.
alter table public.admin_memberships enable row level security;
alter table public.investment_opportunities enable row level security;
alter table public.deposit_requests enable row level security;
alter table public.withdrawal_requests enable row level security;
alter table public.investment_allocations enable row level security;
alter table public.investor_ledger_entries enable row level security;
alter table public.investment_distributions enable row level security;
alter table public.investor_documents enable row level security;
alter table public.admin_audit_logs enable row level security;
alter table public.platform_settings enable row level security;

-- Investors can see their own records; admins can review records.
drop policy if exists "Admin memberships visible to self and admins" on public.admin_memberships;
create policy "Admin memberships visible to self and admins"
on public.admin_memberships for select to authenticated
using (user_id = (select auth.uid()) or public.crystal_is_admin());

drop policy if exists "Supa Admin manages admin memberships" on public.admin_memberships;
create policy "Supa Admin manages admin memberships"
on public.admin_memberships for all to authenticated
using (public.crystal_is_supa_admin())
with check (public.crystal_is_supa_admin());

drop policy if exists "Active opportunities visible to authenticated investors" on public.investment_opportunities;
create policy "Active opportunities visible to authenticated investors"
on public.investment_opportunities for select to authenticated
using (status = 'Active' or public.crystal_is_admin());

drop policy if exists "Admins manage opportunities" on public.investment_opportunities;
create policy "Admins manage opportunities"
on public.investment_opportunities for all to authenticated
using (public.crystal_is_admin()) with check (public.crystal_is_admin());

drop policy if exists "Investors read own deposit requests" on public.deposit_requests;
create policy "Investors read own deposit requests"
on public.deposit_requests for select to authenticated
using (investor_id = (select auth.uid()) or public.crystal_is_admin());

drop policy if exists "Investors submit own deposit requests" on public.deposit_requests;
create policy "Investors submit own deposit requests"
on public.deposit_requests for insert to authenticated
with check (investor_id = (select auth.uid()));

drop policy if exists "Admins review deposit requests" on public.deposit_requests;
create policy "Admins review deposit requests"
on public.deposit_requests for update to authenticated
using (public.crystal_is_admin()) with check (public.crystal_is_admin());

drop policy if exists "Investors read own withdrawal requests" on public.withdrawal_requests;
create policy "Investors read own withdrawal requests"
on public.withdrawal_requests for select to authenticated
using (investor_id = (select auth.uid()) or public.crystal_is_admin());

drop policy if exists "Investors submit own withdrawal requests" on public.withdrawal_requests;
create policy "Investors submit own withdrawal requests"
on public.withdrawal_requests for insert to authenticated
with check (investor_id = (select auth.uid()));

drop policy if exists "Admins review withdrawal requests" on public.withdrawal_requests;
create policy "Admins review withdrawal requests"
on public.withdrawal_requests for update to authenticated
using (public.crystal_is_admin()) with check (public.crystal_is_admin());

drop policy if exists "Investors read own allocations" on public.investment_allocations;
create policy "Investors read own allocations"
on public.investment_allocations for select to authenticated
using (investor_id = (select auth.uid()) or public.crystal_is_admin());

drop policy if exists "Admins manage allocations" on public.investment_allocations;
create policy "Admins manage allocations"
on public.investment_allocations for all to authenticated
using (public.crystal_is_admin()) with check (public.crystal_is_admin());

drop policy if exists "Investors read own ledger" on public.investor_ledger_entries;
create policy "Investors read own ledger"
on public.investor_ledger_entries for select to authenticated
using (investor_id = (select auth.uid()) or public.crystal_is_admin());

drop policy if exists "Admins insert ledger entries" on public.investor_ledger_entries;
create policy "Admins insert ledger entries"
on public.investor_ledger_entries for insert to authenticated
with check (public.crystal_is_admin());

drop policy if exists "Investors read own distributions" on public.investment_distributions;
create policy "Investors read own distributions"
on public.investment_distributions for select to authenticated
using (investor_id = (select auth.uid()) or public.crystal_is_admin());

drop policy if exists "Admins manage distributions" on public.investment_distributions;
create policy "Admins manage distributions"
on public.investment_distributions for all to authenticated
using (public.crystal_is_admin()) with check (public.crystal_is_admin());

drop policy if exists "Investors read own documents" on public.investor_documents;
create policy "Investors read own documents"
on public.investor_documents for select to authenticated
using (investor_id = (select auth.uid()) or public.crystal_is_admin());

drop policy if exists "Investors submit own documents" on public.investor_documents;
create policy "Investors submit own documents"
on public.investor_documents for insert to authenticated
with check (investor_id = (select auth.uid()));

drop policy if exists "Admins review documents" on public.investor_documents;
create policy "Admins review documents"
on public.investor_documents for update to authenticated
using (public.crystal_is_admin()) with check (public.crystal_is_admin());

drop policy if exists "Admins read audit logs" on public.admin_audit_logs;
create policy "Admins read audit logs"
on public.admin_audit_logs for select to authenticated
using (public.crystal_is_admin());

drop policy if exists "Admins create audit logs" on public.admin_audit_logs;
create policy "Admins create audit logs"
on public.admin_audit_logs for insert to authenticated
with check (public.crystal_is_admin() and actor_id = (select auth.uid()));

drop policy if exists "Admins manage platform settings" on public.platform_settings;
create policy "Admins manage platform settings"
on public.platform_settings for all to authenticated
using (public.crystal_is_admin()) with check (public.crystal_is_admin());

-- Explicit grants; RLS remains the row-level boundary.
grant select, insert, update, delete on public.admin_memberships to authenticated;
grant select, insert, update on public.deposit_requests to authenticated;
grant select, insert, update on public.withdrawal_requests to authenticated;
grant select on public.investment_opportunities to authenticated;
grant insert, update, delete on public.investment_opportunities to authenticated;
grant select on public.investment_allocations to authenticated;
grant insert, update, delete on public.investment_allocations to authenticated;
grant select, insert on public.investor_ledger_entries to authenticated;
grant select on public.investment_distributions to authenticated;
grant insert, update, delete on public.investment_distributions to authenticated;
grant select, insert, update on public.investor_documents to authenticated;
grant select, insert on public.admin_audit_logs to authenticated;
grant select, insert, update, delete on public.platform_settings to authenticated;

revoke all on all tables in schema public from anon;
