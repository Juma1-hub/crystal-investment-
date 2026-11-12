# CRYSTAL INVESTMENTS — backend operations update

## Included
- Investor deposit form captures amount, currency, payment method, sender/account name and payment reference.
- Investor withdrawal form captures amount, currency, destination method, account holder, phone/account number, bank details and instructions.
- Deposit and withdrawal requests are submitted through Supabase RPCs and displayed from central request tables.
- Admin deposit/withdrawal review uses permission-checked Supabase RPCs.
- Admin workspace state, investor directory, investor profile edits, administrator memberships and activity feed are stored/read through Supabase rather than browser localStorage.
- Portfolio allocation creation, approval, activation, principal adjustment and closure use Supabase.
- Supa Admin / Junior Admin membership management uses database-backed roles and module permissions.
- Support centre submissions are stored in `crystal_support_messages`; the admin inbox can resolve/reopen messages and clear resolved messages.
- Supa Admin can set an annual interest rate and day-count basis. The database records rate history and calculates simple daily accruals for active allocations, with a maximum one-year accrual period per activation.

## Migrations
Run in order in Supabase SQL Editor:
1. `202611110001_initial_investor_profiles.sql` (already completed)
2. `202611110002_referral_program.sql` (already completed)
3. `202611110003_central_backend_and_referral_admin.sql` (must be run if not already completed)
4. `202611120004_interest_support_and_admin_controls.sql`

## First Supa Admin assignment
After migrations 003 and 004 have succeeded, assign the first Supa Admin using the email of the existing account that should own the platform. Replace `OWNER_EMAIL` with that exact email:

```sql
insert into public.crystal_admin_memberships (user_id, role, permissions, is_active)
select id, 'Supa Admin', '{}'::jsonb, true
from auth.users
where lower(email) = lower('OWNER_EMAIL')
on conflict (user_id) do update
set role = 'Supa Admin', permissions = '{}'::jsonb, is_active = true, updated_at = now();
```

A Junior Admin must already have a registered Auth account before their email can be assigned a role. Supa Admin can then assign that account a restricted module permission set in Admin → Administrator access.

## Earnings calculation
The annual rate is divided by the selected 365- or 360-day basis. Daily accrual is simple interest on the active allocation principal, recorded once per allocation per day. Rate changes apply from their effective date. Accrual stops one year after each allocation's activation date. This calculation must match the investor's signed opportunity terms and verified realised performance; it is not a guaranteed return promise.

A deposit request is not automatically an investment allocation. Once a deposit is verified and approved, an administrator must allocate the funds to an approved opportunity before earnings begin. For a withdrawal from invested capital, the withdrawal must be reviewed and the affected active allocation principal adjusted so future daily accruals use the reduced principal. Historical daily accrual entries are preserved.

## Operational safeguards
- The public browser never writes investor earnings or commissions directly.
- Admin financial decisions are performed through permission-checked database functions and logged.
- Clearing resolved support messages deletes only resolved support inbox rows; open messages remain.
- Clearing the recent activity feed archives activity entries; it does not permanently erase the protected audit trail.
- Payment execution is not included in this update. Deposit requests record payment references for reconciliation; real payment provider integration and live money movement require approved provider configuration and the applicable legal/regulatory authorisations.
