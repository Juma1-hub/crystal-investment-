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


## Additional financial, support and security migrations

Use the exact order and security instructions in `SECURITY-AND-SETUP.md`. In particular, run migrations 003, 004 and 005 after the already completed investor profile and referral migrations. Do not run the older alternate `202611110002_financial_and_admin_foundation.sql` on this migration path.

The admin workspace requires Supabase Auth, an active administrator membership and verified TOTP multi-factor authentication. Supa Admin-only financial-rate and role-management operations are also checked by database functions.
