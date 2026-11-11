-- CRYSTAL INVESTMENTS: referral attribution and earnings-based commissions.
-- Commission is 20% of verified realised earnings, never of deposits or principal.

alter table public.investor_profiles
  add column if not exists referral_code text,
  add column if not exists referred_by uuid references public.investor_profiles(id) on delete set null;

update public.investor_profiles
set referral_code = 'CRY' || upper(substr(replace(id::text, '-', ''), 1, 10))
where referral_code is null;

create unique index if not exists investor_profiles_referral_code_uidx
  on public.investor_profiles (upper(referral_code));

create table if not exists public.referral_relationships (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references public.investor_profiles(id) on delete restrict,
  referred_investor_id uuid not null unique references public.investor_profiles(id) on delete restrict,
  referral_code text not null,
  created_at timestamptz not null default now(),
  constraint referral_relationship_not_self check (referrer_id <> referred_investor_id)
);

-- Verified earnings must originate from a trusted backend/admin workflow.
create table if not exists public.investment_earnings (
  id uuid primary key default gen_random_uuid(),
  investor_id uuid not null references public.investor_profiles(id) on delete restrict,
  investment_reference text not null,
  amount numeric(20, 6) not null check (amount > 0),
  currency text not null check (currency in ('KES','USD','GBP')),
  earning_type text not null default 'realised_profit' check (earning_type in ('realised_profit','interest','income_distribution')),
  status text not null default 'pending' check (status in ('pending','verified','reversed')),
  source_reference text not null unique,
  earned_at timestamptz not null default now(),
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.referral_commissions (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references public.investor_profiles(id) on delete restrict,
  referred_investor_id uuid not null references public.investor_profiles(id) on delete restrict,
  earning_id uuid not null unique references public.investment_earnings(id) on delete restrict,
  commission_rate numeric(5,2) not null default 20.00 check (commission_rate = 20.00),
  eligible_earnings numeric(20,6) not null check (eligible_earnings > 0),
  commission_amount numeric(20,6) not null check (commission_amount > 0),
  currency text not null check (currency in ('KES','USD','GBP')),
  status text not null default 'pending' check (status in ('pending','approved','paid','void')),
  created_at timestamptz not null default now(),
  approved_at timestamptz,
  paid_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz
);

create table if not exists public.crystal_admin_memberships (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('Supa Admin','Junior Admin')),
  permissions jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.is_crystal_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.crystal_admin_memberships m
    where m.user_id = (select auth.uid()) and m.is_active = true
  );
$$;
revoke all on function public.is_crystal_admin() from public, anon;
grant execute on function public.is_crystal_admin() to authenticated;

create or replace function public.can_manage_crystal_referrals()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.crystal_admin_memberships m
    where m.user_id = (select auth.uid()) and m.is_active = true
      and (m.role = 'Supa Admin' or coalesce((m.permissions ->> 'referrals')::boolean, false))
  );
$$;
revoke all on function public.can_manage_crystal_referrals() from public, anon;
grant execute on function public.can_manage_crystal_referrals() to authenticated;

-- Rebuild the auth trigger function so each new investor receives a unique code
-- and a valid referral code supplied during signup is attributed exactly once.
create or replace function public.handle_new_crystal_investor()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_referrer uuid;
  v_code text;
begin
  v_code := 'CRY' || upper(substr(replace(new.id::text, '-', ''), 1, 10));
  select p.id into v_referrer
  from public.investor_profiles p
  where upper(p.referral_code) = upper(coalesce(new.raw_user_meta_data ->> 'referral_code', ''))
    and p.id <> new.id
  limit 1;

  insert into public.investor_profiles (
    id, full_name, phone, country, preferred_currency, terms_accepted_at,
    referral_code, referred_by
  ) values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    coalesce(new.raw_user_meta_data ->> 'country', ''),
    case when new.raw_user_meta_data ->> 'preferred_currency' in ('KES','USD','GBP')
      then new.raw_user_meta_data ->> 'preferred_currency' else 'KES' end,
    nullif(new.raw_user_meta_data ->> 'terms_accepted_at', '')::timestamptz,
    v_code,
    v_referrer
  ) on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function public.handle_new_crystal_investor() from public, anon, authenticated;

create or replace function public.capture_crystal_referral_relationship()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.referred_by is not null then
    insert into public.referral_relationships(referrer_id, referred_investor_id, referral_code)
    values (new.referred_by, new.id, (
      select referral_code from public.investor_profiles where id = new.referred_by
    ))
    on conflict (referred_investor_id) do nothing;
  end if;
  return new;
end;
$$;
revoke all on function public.capture_crystal_referral_relationship() from public, anon, authenticated;
drop trigger if exists capture_crystal_referral_relationship on public.investor_profiles;
create trigger capture_crystal_referral_relationship
  after insert on public.investor_profiles
  for each row execute function public.capture_crystal_referral_relationship();

-- One commission per verified earning, created only after trusted verification.
create or replace function public.create_crystal_referral_commission()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_referrer uuid;
  v_should_create boolean := false;
begin
  if new.status = 'verified' then
    if tg_op = 'INSERT' then
      v_should_create := true;
    else
      v_should_create := old.status is distinct from 'verified';
    end if;
    if v_should_create then
      select referred_by into v_referrer
      from public.investor_profiles where id = new.investor_id;
      if v_referrer is not null then
        insert into public.referral_commissions (
          referrer_id, referred_investor_id, earning_id, commission_rate,
          eligible_earnings, commission_amount, currency
        ) values (
          v_referrer, new.investor_id, new.id, 20.00,
          new.amount, round(new.amount * 0.20, 6), new.currency
        ) on conflict (earning_id) do nothing;
      end if;
    end if;
  elsif new.status = 'reversed' then
    if exists (select 1 from public.referral_commissions where earning_id = new.id and status = 'paid') then
      raise exception 'A paid referral commission requires a separate audited recovery entry.';
    end if;
    update public.referral_commissions
      set status = 'void'
      where earning_id = new.id and status in ('pending','approved');
  end if;
  return new;
end;
$$;
revoke all on function public.create_crystal_referral_commission() from public, anon, authenticated;
drop trigger if exists create_crystal_referral_commission on public.investment_earnings;
create trigger create_crystal_referral_commission
  after insert or update of status on public.investment_earnings
  for each row execute function public.create_crystal_referral_commission();

create or replace function public.admin_set_referral_commission_status(
  p_commission_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_manage_crystal_referrals() then
    raise exception 'Referral management permission required';
  end if;
  if p_status not in ('approved','void') then
    raise exception 'Unsupported commission status';
  end if;
  update public.referral_commissions
  set status = p_status,
      approved_at = case when p_status = 'approved' then now() else approved_at end,
      reviewed_by = (select auth.uid()),
      reviewed_at = now()
  where id = p_commission_id and status = 'pending';
  if not found then raise exception 'Pending commission not found'; end if;
end;
$$;
revoke all on function public.admin_set_referral_commission_status(uuid,text) from public, anon;
grant execute on function public.admin_set_referral_commission_status(uuid,text) to authenticated;

alter table public.referral_relationships enable row level security;
alter table public.investment_earnings enable row level security;
alter table public.referral_commissions enable row level security;
alter table public.crystal_admin_memberships enable row level security;

drop policy if exists "Investors can view their referral relationships" on public.referral_relationships;
create policy "Investors can view their referral relationships"
  on public.referral_relationships for select to authenticated
  using (referrer_id = (select auth.uid()) or referred_investor_id = (select auth.uid()) or public.can_manage_crystal_referrals());

drop policy if exists "Investors can view their own verified earnings" on public.investment_earnings;
create policy "Investors can view their own verified earnings"
  on public.investment_earnings for select to authenticated
  using (investor_id = (select auth.uid()) or public.can_manage_crystal_referrals());

drop policy if exists "Referrers can view their commissions" on public.referral_commissions;
create policy "Referrers can view their commissions"
  on public.referral_commissions for select to authenticated
  using (referrer_id = (select auth.uid()) or public.can_manage_crystal_referrals());

drop policy if exists "Administrators can manage administrator memberships" on public.crystal_admin_memberships;
create policy "Administrators can manage administrator memberships"
  on public.crystal_admin_memberships for select to authenticated
  using (public.is_crystal_admin());

revoke all on public.referral_relationships from anon, authenticated;
revoke all on public.investment_earnings from anon, authenticated;
revoke all on public.referral_commissions from anon, authenticated;
revoke all on public.crystal_admin_memberships from anon, authenticated;
grant select on public.referral_relationships, public.investment_earnings, public.referral_commissions to authenticated;
grant select on public.crystal_admin_memberships to authenticated;

-- No browser-side user may insert earnings or commission records directly.
-- A trusted backend/service-role workflow must create and verify earnings.
