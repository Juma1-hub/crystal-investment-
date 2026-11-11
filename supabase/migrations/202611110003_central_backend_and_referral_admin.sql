-- CRYSTAL INVESTMENTS: centralise dashboard, portfolio, market and site data.
-- Run once in Supabase SQL Editor after migrations 001 and 002.

create table if not exists public.deposit_requests (
 id uuid primary key default gen_random_uuid(),
 investor_id uuid not null references public.investor_profiles(id) on delete restrict,
 amount numeric(20,6) not null check(amount > 0),
 currency text not null check(currency in ('KES','USD','GBP')),
 payment_method text not null default '',
 payment_reference text not null default '',
 status text not null default 'pending' check(status in ('pending','approved','rejected','cancelled')),
 reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.withdrawal_requests (
 id uuid primary key default gen_random_uuid(),
 investor_id uuid not null references public.investor_profiles(id) on delete restrict,
 amount numeric(20,6) not null check(amount > 0),
 currency text not null check(currency in ('KES','USD','GBP')),
 destination_details jsonb not null default '{}'::jsonb,
 status text not null default 'pending' check(status in ('pending','approved','rejected','paid','cancelled')),
 reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.investment_allocations (
 id uuid primary key default gen_random_uuid(),
 investor_id uuid not null references public.investor_profiles(id) on delete restrict,
 project_name text not null,
 amount numeric(20,6) not null check(amount > 0),
 currency text not null check(currency in ('KES','USD','GBP')),
 annual_rate numeric(8,4) not null default 0 check(annual_rate >= 0 and annual_rate <= 100),
 day_count_basis integer not null default 365 check(day_count_basis in (360,365)),
 terms_reference text not null,
 status text not null default 'pending' check(status in ('pending','approved','active','declined','closed')),
 approved_at timestamptz,
 activated_at timestamptz,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now()
);
create table if not exists public.market_conditions (
 id uuid primary key default gen_random_uuid(),
 market text not null,
 sentiment text not null check(sentiment in ('Bullish','Bearish','Neutral')),
 source text not null,
 note text not null default '',
 updated_by uuid references auth.users(id),
 updated_at timestamptz not null default now()
);
create table if not exists public.crystal_site_configuration (
 config_key text primary key check(config_key in ('platform_settings','website_content')),
 config_value jsonb not null default '{}'::jsonb,
 updated_by uuid references auth.users(id),
 updated_at timestamptz not null default now()
);
create table if not exists public.crystal_admin_audit_log (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid references auth.users(id),
 action text not null,
 target_type text not null,
 target_id text,
 details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

alter table public.deposit_requests enable row level security;
alter table public.withdrawal_requests enable row level security;
alter table public.investment_allocations enable row level security;
alter table public.market_conditions enable row level security;
alter table public.crystal_site_configuration enable row level security;
alter table public.crystal_admin_audit_log enable row level security;

-- Investors may see only their own financial records. Writes are controlled by RPCs/admin.
drop policy if exists "investors read own deposits" on public.deposit_requests;
create policy "investors read own deposits" on public.deposit_requests for select to authenticated using(investor_id=(select auth.uid()));
drop policy if exists "investors read own withdrawals" on public.withdrawal_requests;
create policy "investors read own withdrawals" on public.withdrawal_requests for select to authenticated using(investor_id=(select auth.uid()));
drop policy if exists "investors read own allocations" on public.investment_allocations;
create policy "investors read own allocations" on public.investment_allocations for select to authenticated using(investor_id=(select auth.uid()));
drop policy if exists "authenticated read market conditions" on public.market_conditions;
create policy "authenticated read market conditions" on public.market_conditions for select to authenticated using(true);
drop policy if exists "admins read site config" on public.crystal_site_configuration;
create policy "admins read site config" on public.crystal_site_configuration for select to authenticated using(public.is_crystal_admin());
drop policy if exists "admins read audit log" on public.crystal_admin_audit_log;
create policy "admins read audit log" on public.crystal_admin_audit_log for select to authenticated using(public.is_crystal_admin());

revoke all on public.deposit_requests,public.withdrawal_requests,public.investment_allocations,public.market_conditions,public.crystal_site_configuration,public.crystal_admin_audit_log from anon,authenticated;
grant select on public.deposit_requests,public.withdrawal_requests,public.investment_allocations,public.market_conditions to authenticated;
grant select on public.crystal_site_configuration,public.crystal_admin_audit_log to authenticated;

-- Admin RPC guard supports Supa Admin or an explicitly granted module permission.
create or replace function public.crystal_admin_has_permission(p_permission text)
returns boolean language sql stable security definer set search_path=''
as $$
 select exists(select 1 from public.crystal_admin_memberships m
 where m.user_id=(select auth.uid()) and m.is_active=true
 and (m.role='Supa Admin' or coalesce((m.permissions ->> p_permission)::boolean,false)));
$$;
revoke all on function public.crystal_admin_has_permission(text) from public,anon;
grant execute on function public.crystal_admin_has_permission(text) to authenticated;

create or replace function public.admin_update_investor_referral_code(p_investor_id uuid,p_new_code text)
returns void language plpgsql security definer set search_path=''
as $$
declare v_code text;
begin
 if not public.crystal_admin_has_permission('referrals') then raise exception 'Referral management permission required'; end if;
 v_code := upper(regexp_replace(trim(coalesce(p_new_code,'')), '[^A-Za-z0-9_-]', '', 'g'));
 if length(v_code)<4 or length(v_code)>24 then raise exception 'Referral code must be 4 to 24 letters, numbers, underscores or hyphens'; end if;
 if exists(select 1 from public.investor_profiles where upper(referral_code)=v_code and id<>p_investor_id) then raise exception 'That referral code is already in use'; end if;
 update public.investor_profiles set referral_code=v_code where id=p_investor_id;
 if not found then raise exception 'Investor profile not found'; end if;
 update public.referral_relationships set referral_code=v_code where referrer_id=p_investor_id;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id,details)
 values((select auth.uid()),'referral_code_changed','investor',p_investor_id::text,jsonb_build_object('new_code',v_code));
end;
$$;
revoke all on function public.admin_update_investor_referral_code(uuid,text) from public,anon;
grant execute on function public.admin_update_investor_referral_code(uuid,text) to authenticated;

create or replace function public.admin_save_market_condition(p_id uuid,p_market text,p_sentiment text,p_source text,p_note text)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_id uuid;
begin
 if not public.crystal_admin_has_permission('market_conditions') then raise exception 'Market conditions permission required'; end if;
 if p_sentiment not in ('Bullish','Bearish','Neutral') then raise exception 'Invalid sentiment'; end if;
 if p_id is null then
  insert into public.market_conditions(market,sentiment,source,note,updated_by) values(trim(p_market),p_sentiment,trim(p_source),coalesce(p_note,''),(select auth.uid())) returning id into v_id;
 else
  update public.market_conditions set market=trim(p_market),sentiment=p_sentiment,source=trim(p_source),note=coalesce(p_note,''),updated_by=(select auth.uid()),updated_at=now() where id=p_id returning id into v_id;
  if v_id is null then raise exception 'Market record not found'; end if;
 end if;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id) values((select auth.uid()),'market_condition_saved','market_condition',v_id::text);
 return v_id;
end;
$$;
revoke all on function public.admin_save_market_condition(uuid,text,text,text,text) from public,anon;
grant execute on function public.admin_save_market_condition(uuid,text,text,text,text) to authenticated;

create or replace function public.admin_delete_market_condition(p_id uuid)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if not public.crystal_admin_has_permission('market_conditions') then raise exception 'Market conditions permission required'; end if;
 delete from public.market_conditions where id=p_id;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id) values((select auth.uid()),'market_condition_deleted','market_condition',p_id::text);
end;
$$;
revoke all on function public.admin_delete_market_condition(uuid) from public,anon;
grant execute on function public.admin_delete_market_condition(uuid) to authenticated;

create or replace function public.admin_save_site_configuration(p_key text,p_value jsonb)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if not public.crystal_admin_has_permission('website_content') and not public.crystal_admin_has_permission('platform_settings') then raise exception 'Site management permission required'; end if;
 if p_key not in ('platform_settings','website_content') then raise exception 'Invalid configuration key'; end if;
 insert into public.crystal_site_configuration(config_key,config_value,updated_by) values(p_key,p_value,(select auth.uid()))
 on conflict(config_key) do update set config_value=excluded.config_value,updated_by=excluded.updated_by,updated_at=now();
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id) values((select auth.uid()),'site_configuration_saved',p_key,p_key);
end;
$$;
revoke all on function public.admin_save_site_configuration(text,jsonb) from public,anon;
grant execute on function public.admin_save_site_configuration(text,jsonb) to authenticated;

-- Admins with referral-management access can inspect investor directory for code maintenance.
drop policy if exists "Admins can view investor profiles" on public.investor_profiles;
create policy "Admins can view investor profiles" on public.investor_profiles
 for select to authenticated using (public.is_crystal_admin());

create or replace function public.investor_submit_deposit(p_amount numeric,p_currency text,p_method text,p_reference text)
returns uuid language plpgsql security definer set search_path=''
as $$ declare v_id uuid; begin
 if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
 if p_amount<=0 or p_currency not in ('KES','USD','GBP') then raise exception 'Invalid deposit amount or currency'; end if;
 insert into public.deposit_requests(investor_id,amount,currency,payment_method,payment_reference)
 values((select auth.uid()),p_amount,p_currency,coalesce(p_method,''),coalesce(p_reference,'')) returning id into v_id;
 return v_id;
end $$;
revoke all on function public.investor_submit_deposit(numeric,text,text,text) from public,anon;
grant execute on function public.investor_submit_deposit(numeric,text,text,text) to authenticated;

create or replace function public.investor_submit_withdrawal(p_amount numeric,p_currency text,p_destination jsonb)
returns uuid language plpgsql security definer set search_path=''
as $$ declare v_id uuid; begin
 if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
 if p_amount<=0 or p_currency not in ('KES','USD','GBP') then raise exception 'Invalid withdrawal amount or currency'; end if;
 insert into public.withdrawal_requests(investor_id,amount,currency,destination_details)
 values((select auth.uid()),p_amount,p_currency,coalesce(p_destination,'{}'::jsonb)) returning id into v_id;
 return v_id;
end $$;
revoke all on function public.investor_submit_withdrawal(numeric,text,jsonb) from public,anon;
grant execute on function public.investor_submit_withdrawal(numeric,text,jsonb) to authenticated;
