# CRYSTAL INVESTMENTS — Supabase connection

This update connects investor registration, email/password sign-in, sign-out and basic investor profile records to the CRYSTAL INVESTMENTS Supabase project.

## 1. Add the environment variables in Vercel

1. Open the CRYSTAL INVESTMENTS project in Vercel.
2. Open **Settings → Environment Variables**.
3. Add `NEXT_PUBLIC_SUPABASE_URL` with this value:
   `https://unzfihzrisczmtozdszs.supabase.co`
4. Add `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` with the publishable key supplied in the ChatGPT conversation.
5. Enable the variables for **Production**, **Preview** and **Development**, then save.
6. Do not add a service-role key or database password to the website environment.

For local development, copy `.env.example` to `.env.local` and fill in the same two values. Never upload `.env.local` to GitHub.

## 2. Create the investor profile table

1. Open the Supabase project `unzfihzrisczmtozdszs`.
2. Open **SQL Editor → New query**.
3. Open `supabase/migrations/202611110001_initial_investor_profiles.sql` in this project ZIP.
4. Copy the entire SQL file into the Supabase SQL Editor and click **Run**.
5. Confirm that `investor_profiles` appears under **Table Editor**.

The migration creates a profile row automatically when a Supabase Auth user is created. Row Level Security ensures each investor can read and update only their own profile. Investors cannot assign themselves administrator permissions.

## 3. Configure email confirmation

In Supabase, open **Authentication → URL Configuration**:

- Set **Site URL** to the actual deployed CRYSTAL INVESTMENTS website origin.
- Add the deployed website's `/login` address to **Redirect URLs**.
- Add `http://localhost:3000/login` only if you will test locally.

Keep email confirmation enabled. Configure a reliable SMTP sender before inviting real users; the default Supabase email service has sending limits.

## 4. Deploy and test

After saving the Vercel environment variables and running the SQL migration, redeploy the Vercel project. Test with a new email address:

1. Register and accept the Terms & Conditions.
2. Confirm the email using the link sent by Supabase.
3. Sign in.
4. Refresh the investor dashboard and confirm the session remains active.
5. Open **Profile & security**, update the phone or preferred currency, and save.
6. Sign out and sign in again.
7. In Supabase, confirm the user appears in **Authentication → Users** and the matching row appears in **Table Editor → investor_profiles**.

## Scope of this connection

This phase connects Supabase Auth and basic investor profiles. Deposits, withdrawals, investment allocations, distributions, investor balances, admin roles, admin records, website settings and market data have not yet been migrated from browser storage. The investor dashboard therefore does not display browser-stored figures as live financial balances, and deposit/withdrawal actions remain unavailable. Payment integration is a separate next phase and must remain disabled until regulatory and provider approvals are confirmed.


## 5. Enable the referral programme

1. Open `supabase/migrations/202611110002_referral_program.sql`.
2. Run the complete file in **Supabase → SQL Editor** after the investor profile migration has succeeded.
3. The migration adds a unique referral code to every investor profile, captures an optional referral code during signup, records each referral once, and creates a commission equal to 20% only when a trusted backend marks a referred investor's realised earnings as `verified`.
4. Commission records are held in the same currency as the underlying verified earnings. KES, USD and GBP are never combined.
5. The investor dashboard includes a Referral Programme section with a personal link, referral counts and commission history. The admin console includes a Referral Programme review area.

### Administrator access for referral review

The referral review screen requires an active row in `crystal_admin_memberships`. After identifying the correct administrator's UUID under **Supabase → Authentication → Users**, a project owner can bootstrap the first Supa Admin from the SQL Editor using this statement, replacing the UUID with the intended administrator account only:

```sql
insert into public.crystal_admin_memberships (user_id, role, permissions, is_active)
values ('REPLACE-WITH-ADMIN-AUTH-USER-UUID', 'Supa Admin', '{"referrals": true}', true)
on conflict (user_id) do update
set role = excluded.role, permissions = excluded.permissions, is_active = true;
```

Do not promote a normal investor account. Only grant this role to the designated company administrator. Junior Admins need `{"referrals": true}` in their permissions to review referral commissions; otherwise they cannot access the referral review data.

### Earnings and commission controls

The browser cannot create earnings or commissions. A trusted server-side process must insert an earning and mark it `verified` only after the underlying realised investment earnings have been confirmed. The database trigger then creates one 20% commission for the referrer. Pending commissions can be approved or voided by an authorised administrator. Marking a commission as paid must be performed by the trusted payment/distribution workflow, not by a browser update. Deposits, principal, projected returns and unverified figures do not generate commissions.

The referral tables and workflow are prepared here; the existing deposits, allocations and realised earnings are not yet integrated into a trusted end-to-end financial ledger. Do not manually insert fictional earnings to test commissions.


## Central dashboard data and administrator referral-code controls

After migrations `202611110001_initial_investor_profiles.sql` and
`202611110002_referral_program.sql`, run:

`supabase/migrations/202611110003_central_backend_and_referral_admin.sql`

This migration creates central tables and protected RPCs for deposit/withdrawal
requests, investment allocations, market-condition updates, site configuration,
and administrator audit records. It also adds the Supa Admin / permitted Junior
Admin RPC used to change a client's referral code. Referral code changes are
unique, update the referral relationship's displayed code, and create an audit
entry. Historical commissions are not rewritten.

The investor portal no longer reads/writes browser localStorage for account
currency or investor financial record loading. Deposit and withdrawal request
submission is routed through authenticated Supabase RPCs. The corresponding
financial request tables are read-only to clients; status changes must be made
through trusted administrator workflows.

Market condition publishing and platform settings / website content saving
now use Supabase RPCs and database tables instead of browser localStorage.

Important: the existing AdminConsole workspace state and the portfolio
allocation manager still contain legacy browser-storage paths in this version.
They must be migrated to the new database tables and secure administrator
workflows before claiming the entire admin workspace is fully centralised.
Do not enable live payment, deposit settlement, withdrawal payout, or investment
activation until the corresponding server-side review, ledger reconciliation,
and regulatory controls are implemented and tested.
