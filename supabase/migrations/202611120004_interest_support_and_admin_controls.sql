-- CRYSTAL INVESTMENTS: earnings schedule, support inbox and secure admin controls.
-- Run after migrations 001, 002 and 003.

create table if not exists public.crystal_interest_rate_history (
  id uuid primary key default gen_random_uuid(),
  annual_rate numeric(8,4) not null check (annual_rate >= 0 and annual_rate <= 100),
  day_count_basis integer not null check (day_count_basis in (360,365)),
  effective_at timestamptz not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists crystal_interest_rate_effective_idx on public.crystal_interest_rate_history(effective_at desc);

create table if not exists public.investment_daily_accruals (
  id uuid primary key default gen_random_uuid(),
  allocation_id uuid not null references public.investment_allocations(id) on delete restrict,
  investor_id uuid not null references public.investor_profiles(id) on delete restrict,
  accrual_date date not null,
  principal_basis numeric(20,6) not null check(principal_basis >= 0),
  annual_rate numeric(8,4) not null,
  day_count_basis integer not null check(day_count_basis in (360,365)),
  amount numeric(20,6) not null check(amount >= 0),
  currency text not null check(currency in ('KES','USD','GBP')),
  created_at timestamptz not null default now(),
  unique(allocation_id,accrual_date)
);
create index if not exists investment_daily_accruals_investor_idx on public.investment_daily_accruals(investor_id,accrual_date desc);

create table if not exists public.crystal_support_messages (
  id uuid primary key default gen_random_uuid(),
  investor_id uuid references public.investor_profiles(id) on delete set null,
  sender_name text not null,
  sender_email text not null,
  category text not null default 'General enquiry',
  subject text not null default 'Investor enquiry',
  message text not null,
  status text not null default 'open' check(status in ('open','resolved')),
  resolved_by uuid references auth.users(id),
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.crystal_interest_rate_history enable row level security;
alter table public.investment_daily_accruals enable row level security;
alter table public.crystal_support_messages enable row level security;
drop policy if exists "Investors read own daily accruals" on public.investment_daily_accruals;
create policy "Investors read own daily accruals" on public.investment_daily_accruals for select to authenticated using(investor_id=(select auth.uid()));
drop policy if exists "Admins read interest rate history" on public.crystal_interest_rate_history;
create policy "Admins read interest rate history" on public.crystal_interest_rate_history for select to authenticated using(public.is_crystal_admin());
drop policy if exists "Admins read support inbox" on public.crystal_support_messages;
create policy "Admins read support inbox" on public.crystal_support_messages for select to authenticated using(public.is_crystal_admin());
revoke all on public.crystal_interest_rate_history,public.investment_daily_accruals,public.crystal_support_messages from anon,authenticated;
grant select on public.crystal_interest_rate_history to authenticated;
grant select on public.investment_daily_accruals to authenticated;
grant select on public.crystal_support_messages to authenticated;

create or replace function public.admin_set_global_interest_rate(p_annual_rate numeric,p_day_count_basis integer,p_effective_at timestamptz default now())
returns uuid language plpgsql security definer set search_path=''
as $$ declare v_id uuid; begin
 if not public.crystal_admin_has_permission('interest_rates') then raise exception 'Interest-rate management permission required'; end if;
 if p_annual_rate<0 or p_annual_rate>100 or p_day_count_basis not in (360,365) then raise exception 'Invalid annual rate or day-count basis'; end if;
 if p_effective_at>now()+interval '1 day' then raise exception 'Effective date cannot be more than one day in the future'; end if;
 insert into public.crystal_interest_rate_history(annual_rate,day_count_basis,effective_at,created_by)
 values(p_annual_rate,p_day_count_basis,coalesce(p_effective_at,now()),(select auth.uid())) returning id into v_id;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id,details)
 values((select auth.uid()),'global_interest_rate_changed','interest_rate',v_id::text,jsonb_build_object('annual_rate',p_annual_rate,'day_count_basis',p_day_count_basis,'effective_at',p_effective_at));
 return v_id;
end $$;
revoke all on function public.admin_set_global_interest_rate(numeric,integer,timestamptz) from public,anon;
grant execute on function public.admin_set_global_interest_rate(numeric,integer,timestamptz) to authenticated;

create or replace function public.investor_accrue_daily_earnings()
returns void language plpgsql security definer set search_path=''
as $$
declare v_user uuid := (select auth.uid());
begin
 if v_user is null then raise exception 'Authentication required'; end if;
 insert into public.investment_daily_accruals(allocation_id,investor_id,accrual_date,principal_basis,annual_rate,day_count_basis,amount,currency)
 select a.id,a.investor_id,days.accrual_date,a.amount,rate.annual_rate,rate.day_count_basis,
        round(a.amount*rate.annual_rate/100/rate.day_count_basis,6),a.currency
 from public.investment_allocations a
 cross join lateral generate_series(greatest(a.activated_at::date, (select min(effective_at)::date from public.crystal_interest_rate_history)),least(current_date,(a.activated_at::date + interval '1 year' - interval '1 day')::date),interval '1 day') g(day_value)
 cross join lateral (select g.day_value::date as accrual_date) days
 cross join lateral (select h.annual_rate,h.day_count_basis from public.crystal_interest_rate_history h where h.effective_at::date<=days.accrual_date order by h.effective_at desc limit 1) rate
 where a.investor_id=v_user and a.status='active' and a.activated_at is not null
   and exists(select 1 from public.crystal_interest_rate_history)
 on conflict(allocation_id,accrual_date) do nothing;
end $$;
revoke all on function public.investor_accrue_daily_earnings() from public,anon;
grant execute on function public.investor_accrue_daily_earnings() to authenticated;

create or replace function public.investor_get_earnings_summary()
returns table(currency text,principal numeric,daily_earnings numeric,accumulated_earnings numeric)
language plpgsql security definer set search_path=''
as $$ begin
 perform public.investor_accrue_daily_earnings();
 return query
 select a.currency,coalesce(sum(a.amount),0)::numeric,
        coalesce(sum(a.amount*coalesce((select h.annual_rate from public.crystal_interest_rate_history h where h.effective_at<=now() order by h.effective_at desc limit 1),0)/100/coalesce((select h.day_count_basis from public.crystal_interest_rate_history h where h.effective_at<=now() order by h.effective_at desc limit 1),365)),0)::numeric,
        coalesce((select sum(d.amount) from public.investment_daily_accruals d where d.investor_id=(select auth.uid()) and d.currency=a.currency),0)::numeric
 from public.investment_allocations a where a.investor_id=(select auth.uid()) and a.status='active'
 group by a.currency;
end $$;
revoke all on function public.investor_get_earnings_summary() from public,anon;
grant execute on function public.investor_get_earnings_summary() to authenticated;

create or replace function public.investor_create_support_message(p_name text,p_email text,p_category text,p_subject text,p_message text)
returns uuid language plpgsql security definer set search_path=''
as $$ declare v_id uuid; begin
 if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
 if length(trim(coalesce(p_message,'')))<5 or length(trim(coalesce(p_email,'')))<5 then raise exception 'Please provide a valid email and message'; end if;
 insert into public.crystal_support_messages(investor_id,sender_name,sender_email,category,subject,message)
 values((select auth.uid()),left(trim(coalesce(p_name,'')),160),left(trim(p_email),254),left(trim(coalesce(p_category,'General enquiry')),80),left(trim(coalesce(p_subject,'Investor enquiry')),180),left(trim(p_message),10000)) returning id into v_id;
 return v_id;
end $$;
revoke all on function public.investor_create_support_message(text,text,text,text,text) from public,anon;
grant execute on function public.investor_create_support_message(text,text,text,text,text) to authenticated;

create or replace function public.admin_update_support_message(p_message_id uuid,p_status text)
returns void language plpgsql security definer set search_path=''
as $$ begin
 if not public.crystal_admin_has_permission('support') then raise exception 'Support inbox permission required'; end if;
 if p_status not in ('open','resolved') then raise exception 'Invalid support status'; end if;
 update public.crystal_support_messages set status=p_status,resolved_by=case when p_status='resolved' then (select auth.uid()) else null end,resolved_at=case when p_status='resolved' then now() else null end where id=p_message_id;
 if not found then raise exception 'Support message not found'; end if;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id,details) values((select auth.uid()),'support_message_status_changed','support_message',p_message_id::text,jsonb_build_object('status',p_status));
end $$;
revoke all on function public.admin_update_support_message(uuid,text) from public,anon;
grant execute on function public.admin_update_support_message(uuid,text) to authenticated;

create or replace function public.admin_clear_resolved_support_messages()
returns integer language plpgsql security definer set search_path=''
as $$ declare v_count integer; begin
 if not public.crystal_admin_has_permission('support') then raise exception 'Support inbox permission required'; end if;
 delete from public.crystal_support_messages where status='resolved'; get diagnostics v_count=row_count;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,details) values((select auth.uid()),'resolved_support_messages_cleared','support_message',jsonb_build_object('deleted_count',v_count));
 return v_count;
end $$;
revoke all on function public.admin_clear_resolved_support_messages() from public,anon;
grant execute on function public.admin_clear_resolved_support_messages() to authenticated;

create or replace function public.admin_review_financial_request(p_request_type text,p_request_id uuid,p_status text)
returns void language plpgsql security definer set search_path=''
as $$ begin
 if p_status not in ('approved','rejected') then raise exception 'Invalid review status'; end if;
 if p_request_type='deposit' then
  if not public.crystal_admin_has_permission('deposit_approvals') then raise exception 'Deposit approval permission required'; end if;
  update public.deposit_requests set status=p_status,reviewed_by=(select auth.uid()),reviewed_at=now() where id=p_request_id;
 elsif p_request_type='withdrawal' then
  if not public.crystal_admin_has_permission('withdrawal_approvals') then raise exception 'Withdrawal approval permission required'; end if;
  update public.withdrawal_requests set status=p_status,reviewed_by=(select auth.uid()),reviewed_at=now() where id=p_request_id;
 else raise exception 'Invalid request type'; end if;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id,details) values((select auth.uid()),'financial_request_reviewed',p_request_type,p_request_id::text,jsonb_build_object('status',p_status));
end $$;
revoke all on function public.admin_review_financial_request(text,uuid,text) from public,anon;
grant execute on function public.admin_review_financial_request(text,uuid,text) to authenticated;

-- Extend deposit request metadata for payment reconciliation.
alter table public.deposit_requests add column if not exists sender_name text not null default '';
create or replace function public.investor_submit_deposit(p_amount numeric,p_currency text,p_method text,p_reference text,p_sender_name text default '')
returns uuid language plpgsql security definer set search_path=''
as $$ declare v_id uuid; begin
 if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
 if p_amount<=0 or p_currency not in ('KES','USD','GBP') then raise exception 'Invalid deposit amount or currency'; end if;
 insert into public.deposit_requests(investor_id,amount,currency,payment_method,payment_reference,sender_name)
 values((select auth.uid()),p_amount,p_currency,coalesce(p_method,''),coalesce(p_reference,''),coalesce(p_sender_name,'')) returning id into v_id;
 return v_id;
end $$;
revoke all on function public.investor_submit_deposit(numeric,text,text,text) from public,anon,authenticated;
revoke all on function public.investor_submit_deposit(numeric,text,text,text,text) from public,anon;
grant execute on function public.investor_submit_deposit(numeric,text,text,text,text) to authenticated;

-- Central administrator membership management. Supa Admin is the only role
-- allowed to appoint, promote, demote or remove administrator memberships.
create or replace function public.admin_list_memberships()
returns table(user_id uuid,email text,role text,permissions jsonb,is_active boolean)
language sql security definer set search_path=''
as $$
 select m.user_id,u.email,m.role,m.permissions,m.is_active
 from public.crystal_admin_memberships m join auth.users u on u.id=m.user_id
 where exists(select 1 from public.crystal_admin_memberships x where x.user_id=(select auth.uid()) and x.role='Supa Admin' and x.is_active=true)
 order by m.created_at;
$$;
revoke all on function public.admin_list_memberships() from public,anon;
grant execute on function public.admin_list_memberships() to authenticated;

create or replace function public.admin_set_membership(p_email text,p_role text,p_permissions jsonb default '{}'::jsonb)
returns uuid language plpgsql security definer set search_path=''
as $$ declare v_uid uuid; v_id uuid; begin
 if not exists(select 1 from public.crystal_admin_memberships where user_id=(select auth.uid()) and role='Supa Admin' and is_active=true) then raise exception 'Supa Admin permission required'; end if;
 if p_role not in ('Supa Admin','Junior Admin') then raise exception 'Invalid administrator role'; end if;
 select id into v_uid from auth.users where lower(email)=lower(trim(p_email));
 if v_uid is null then raise exception 'Create the administrator login account first, then assign its role'; end if;
 insert into public.crystal_admin_memberships(user_id,role,permissions,is_active)
 values(v_uid,p_role,coalesce(p_permissions,'{}'::jsonb),true)
 on conflict(user_id) do update set role=excluded.role,permissions=excluded.permissions,is_active=true,updated_at=now()
 returning user_id into v_id;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id,details) values((select auth.uid()),'administrator_membership_set','admin',v_id::text,jsonb_build_object('email',lower(trim(p_email)),'role',p_role,'permissions',p_permissions));
 return v_id;
end $$;
revoke all on function public.admin_set_membership(text,text,jsonb) from public,anon;
grant execute on function public.admin_set_membership(text,text,jsonb) to authenticated;

create or replace function public.admin_remove_membership(p_user_id uuid)
returns void language plpgsql security definer set search_path=''
as $$ declare v_role text; v_count integer; begin
 if not exists(select 1 from public.crystal_admin_memberships where user_id=(select auth.uid()) and role='Supa Admin' and is_active=true) then raise exception 'Supa Admin permission required'; end if;
 select role into v_role from public.crystal_admin_memberships where user_id=p_user_id and is_active=true;
 if v_role='Supa Admin' then select count(*) into v_count from public.crystal_admin_memberships where role='Supa Admin' and is_active=true; if v_count<=1 then raise exception 'The last Supa Admin cannot be removed'; end if; end if;
 update public.crystal_admin_memberships set is_active=false,updated_at=now() where user_id=p_user_id;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id) values((select auth.uid()),'administrator_membership_removed','admin',p_user_id::text);
end $$;
revoke all on function public.admin_remove_membership(uuid) from public,anon;
grant execute on function public.admin_remove_membership(uuid) to authenticated;

-- Portfolio allocation functions keep investor allocations and their terms in Supabase.
drop policy if exists "Admins read investor allocations" on public.investment_allocations;
create policy "Admins read investor allocations" on public.investment_allocations for select to authenticated using(public.is_crystal_admin());

create or replace function public.admin_create_investment_allocation(p_investor_email text,p_project_name text,p_amount numeric,p_currency text,p_terms_reference text)
returns uuid language plpgsql security definer set search_path=''
as $$ declare v_investor uuid; v_id uuid; begin
 if not public.crystal_admin_has_permission('portfolio') then raise exception 'Portfolio management permission required'; end if;
 if p_amount<=0 or p_currency not in ('KES','USD','GBP') or length(trim(coalesce(p_terms_reference,'')))<3 then raise exception 'Invalid allocation details'; end if;
 select p.id into v_investor from public.investor_profiles p join auth.users u on u.id=p.id where lower(u.email)=lower(trim(p_investor_email));
 if v_investor is null then raise exception 'Investor account not found'; end if;
 insert into public.investment_allocations(investor_id,project_name,amount,currency,annual_rate,terms_reference,status,created_by)
 values(v_investor,trim(p_project_name),p_amount,p_currency,0,trim(p_terms_reference),'pending',(select auth.uid())) returning id into v_id;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id,details) values((select auth.uid()),'investment_allocation_created','investment_allocation',v_id::text,jsonb_build_object('investor_email',lower(trim(p_investor_email)),'amount',p_amount,'currency',p_currency));
 return v_id;
end $$;
revoke all on function public.admin_create_investment_allocation(text,text,numeric,text,text) from public,anon;
grant execute on function public.admin_create_investment_allocation(text,text,numeric,text,text) to authenticated;

create or replace function public.admin_set_investment_allocation_status(p_allocation_id uuid,p_status text)
returns void language plpgsql security definer set search_path=''
as $$ begin
 if not public.crystal_admin_has_permission('portfolio') then raise exception 'Portfolio management permission required'; end if;
 if p_status not in ('approved','active','declined','closed') then raise exception 'Invalid allocation status'; end if;
 update public.investment_allocations set status=p_status,
   approved_at=case when p_status in ('approved','active') then coalesce(approved_at,now()) else approved_at end,
   activated_at=case when p_status='active' then coalesce(activated_at,now()) else activated_at end
 where id=p_allocation_id;
 if not found then raise exception 'Investment allocation not found'; end if;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id,details) values((select auth.uid()),'investment_allocation_status_changed','investment_allocation',p_allocation_id::text,jsonb_build_object('status',p_status));
end $$;
revoke all on function public.admin_set_investment_allocation_status(uuid,text) from public,anon;
grant execute on function public.admin_set_investment_allocation_status(uuid,text) to authenticated;

create or replace function public.admin_list_investment_allocations()
returns table(id uuid,investor_id uuid,investor_email text,project_name text,amount numeric,currency text,status text,terms_reference text,created_at timestamptz,activated_at timestamptz)
language sql security definer set search_path=''
as $$
 select a.id,a.investor_id,u.email,a.project_name,a.amount,a.currency,a.status,a.terms_reference,a.created_at,a.activated_at
 from public.investment_allocations a join auth.users u on u.id=a.investor_id
 where public.crystal_admin_has_permission('portfolio') order by a.created_at desc;
$$;
revoke all on function public.admin_list_investment_allocations() from public,anon;
grant execute on function public.admin_list_investment_allocations() to authenticated;

-- Permit authorised administrators to review pending financial requests; all mutations remain RPC-only.
drop policy if exists "Admins read deposit requests" on public.deposit_requests;
create policy "Admins read deposit requests" on public.deposit_requests for select to authenticated using(public.is_crystal_admin());
drop policy if exists "Admins read withdrawal requests" on public.withdrawal_requests;
create policy "Admins read withdrawal requests" on public.withdrawal_requests for select to authenticated using(public.is_crystal_admin());

create or replace function public.admin_adjust_investment_allocation_principal(p_allocation_id uuid,p_new_principal numeric)
returns void language plpgsql security definer set search_path=''
as $$ begin
 if not public.crystal_admin_has_permission('portfolio') then raise exception 'Portfolio management permission required'; end if;
 if p_new_principal<0 then raise exception 'Principal cannot be negative'; end if;
 update public.investment_allocations set amount=p_new_principal where id=p_allocation_id and status='active';
 if not found then raise exception 'Active investment allocation not found'; end if;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id,details) values((select auth.uid()),'investment_principal_adjusted','investment_allocation',p_allocation_id::text,jsonb_build_object('new_principal',p_new_principal));
end $$;
revoke all on function public.admin_adjust_investment_allocation_principal(uuid,numeric) from public,anon;
grant execute on function public.admin_adjust_investment_allocation_principal(uuid,numeric) to authenticated;

create table if not exists public.crystal_admin_workspace_state (
  singleton boolean primary key default true check(singleton=true),
  state jsonb not null default '{}'::jsonb,
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);
alter table public.crystal_admin_workspace_state enable row level security;
drop policy if exists "Admins read workspace state" on public.crystal_admin_workspace_state;
create policy "Admins read workspace state" on public.crystal_admin_workspace_state for select to authenticated using(public.is_crystal_admin());
revoke all on public.crystal_admin_workspace_state from anon,authenticated;
grant select on public.crystal_admin_workspace_state to authenticated;

create or replace function public.admin_save_workspace_state(p_state jsonb)
returns void language plpgsql security definer set search_path=''
as $$ begin
 if not public.crystal_admin_has_permission('admin_workspace') then raise exception 'Administrator workspace permission required'; end if;
 insert into public.crystal_admin_workspace_state(singleton,state,updated_by,updated_at) values(true,coalesce(p_state,'{}'::jsonb),(select auth.uid()),now())
 on conflict(singleton) do update set state=excluded.state,updated_by=excluded.updated_by,updated_at=now();
end $$;
revoke all on function public.admin_save_workspace_state(jsonb) from public,anon;
grant execute on function public.admin_save_workspace_state(jsonb) to authenticated;

create or replace function public.admin_list_investors()
returns table(id uuid,email text,full_name text,phone text,country text,preferred_currency text,referral_code text)
language sql security definer set search_path=''
as $$
 select p.id,u.email,p.full_name,p.phone,p.country,p.preferred_currency,p.referral_code
 from public.investor_profiles p join auth.users u on u.id=p.id
 where public.crystal_admin_has_permission('investors') order by p.created_at desc;
$$;
revoke all on function public.admin_list_investors() from public,anon;
grant execute on function public.admin_list_investors() to authenticated;

create or replace function public.admin_update_investor_profile(p_investor_id uuid,p_full_name text,p_phone text,p_country text)
returns void language plpgsql security definer set search_path=''
as $$ begin
 if not public.crystal_admin_has_permission('investors') then raise exception 'Investor management permission required'; end if;
 update public.investor_profiles set full_name=left(coalesce(p_full_name,''),160),phone=left(coalesce(p_phone,''),60),country=left(coalesce(p_country,''),100) where id=p_investor_id;
 if not found then raise exception 'Investor not found'; end if;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,target_id) values((select auth.uid()),'investor_profile_updated','investor',p_investor_id::text);
end $$;
revoke all on function public.admin_update_investor_profile(uuid,text,text,text) from public,anon;
grant execute on function public.admin_update_investor_profile(uuid,text,text,text) to authenticated;


-- Archive the recent activity feed without destroying the protected audit history.
alter table public.crystal_admin_audit_log add column if not exists archived_at timestamptz;
create or replace function public.admin_clear_activity_feed()
returns integer language plpgsql security definer set search_path=''
as $$ declare v_count integer; begin
 if not public.crystal_admin_has_permission('admin_workspace') then raise exception 'Administrator workspace permission required'; end if;
 update public.crystal_admin_audit_log set archived_at=now() where archived_at is null; get diagnostics v_count=row_count;
 insert into public.crystal_admin_audit_log(actor_id,action,target_type,details) values((select auth.uid()),'recent_activity_feed_cleared','audit_log',jsonb_build_object('archived_count',v_count));
 return v_count;
end $$;
revoke all on function public.admin_clear_activity_feed() from public,anon;
grant execute on function public.admin_clear_activity_feed() to authenticated;


-- Tighten row visibility to the exact Junior Admin module permission.
drop policy if exists "Admins read interest rate history" on public.crystal_interest_rate_history;
create policy "Admins read interest rate history" on public.crystal_interest_rate_history for select to authenticated using(public.crystal_admin_has_permission('interest_rates'));
drop policy if exists "Admins read support inbox" on public.crystal_support_messages;
create policy "Admins read support inbox" on public.crystal_support_messages for select to authenticated using(public.crystal_admin_has_permission('support'));
drop policy if exists "Admins read deposit requests" on public.deposit_requests;
create policy "Admins read deposit requests" on public.deposit_requests for select to authenticated using(public.crystal_admin_has_permission('deposit_approvals'));
drop policy if exists "Admins read withdrawal requests" on public.withdrawal_requests;
create policy "Admins read withdrawal requests" on public.withdrawal_requests for select to authenticated using(public.crystal_admin_has_permission('withdrawal_approvals'));
drop policy if exists "Admins read investor allocations" on public.investment_allocations;
create policy "Admins read investor allocations" on public.investment_allocations for select to authenticated using(public.crystal_admin_has_permission('portfolio'));
drop policy if exists "Admins read workspace state" on public.crystal_admin_workspace_state;
create policy "Admins read workspace state" on public.crystal_admin_workspace_state for select to authenticated using(public.crystal_admin_has_permission('admin_workspace'));
