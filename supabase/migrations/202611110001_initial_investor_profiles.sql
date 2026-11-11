-- CRYSTAL INVESTMENTS: authentication-linked investor profiles.
-- Run this migration in the Supabase SQL Editor for project unzfihzrisczmtozdszs.

create table if not exists public.investor_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text not null default '',
  country text not null default '',
  preferred_currency text not null default 'KES'
    check (preferred_currency in ('KES', 'USD', 'GBP')),
  terms_accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.investor_profiles enable row level security;

-- Remove any previous policies with these names so the migration can be re-run safely.
drop policy if exists "Investors can view their own profile" on public.investor_profiles;
drop policy if exists "Investors can update their own profile" on public.investor_profiles;

create policy "Investors can view their own profile"
  on public.investor_profiles for select
  to authenticated
  using (auth.uid() = id);

create policy "Investors can update their own profile"
  on public.investor_profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Authenticated users may read and update only their own profile row.
grant select on public.investor_profiles to authenticated;
revoke update on public.investor_profiles from authenticated;
grant update (full_name, phone, country, preferred_currency) on public.investor_profiles to authenticated;
revoke all on public.investor_profiles from anon;

create or replace function public.handle_new_crystal_investor()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.investor_profiles (
    id, full_name, phone, country, preferred_currency, terms_accepted_at
  ) values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    coalesce(new.raw_user_meta_data ->> 'country', ''),
    case
      when new.raw_user_meta_data ->> 'preferred_currency' in ('KES', 'USD', 'GBP')
        then new.raw_user_meta_data ->> 'preferred_currency'
      else 'KES'
    end,
    nullif(new.raw_user_meta_data ->> 'terms_accepted_at', '')::timestamptz
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function public.handle_new_crystal_investor() from public, anon, authenticated;

drop trigger if exists on_auth_user_created_crystal_profile on auth.users;
create trigger on_auth_user_created_crystal_profile
after insert on auth.users
for each row execute procedure public.handle_new_crystal_investor();

create or replace function public.set_crystal_profile_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_crystal_profile_updated_at on public.investor_profiles;
create trigger set_crystal_profile_updated_at
before update on public.investor_profiles
for each row execute procedure public.set_crystal_profile_updated_at();

-- Backfill profiles for any auth users that existed before this migration.
insert into public.investor_profiles (
  id, full_name, phone, country, preferred_currency, terms_accepted_at
)
select
  u.id,
  coalesce(u.raw_user_meta_data ->> 'full_name', ''),
  coalesce(u.raw_user_meta_data ->> 'phone', ''),
  coalesce(u.raw_user_meta_data ->> 'country', ''),
  case
    when u.raw_user_meta_data ->> 'preferred_currency' in ('KES', 'USD', 'GBP')
      then u.raw_user_meta_data ->> 'preferred_currency'
    else 'KES'
  end,
  nullif(u.raw_user_meta_data ->> 'terms_accepted_at', '')::timestamptz
from auth.users u
on conflict (id) do nothing;
