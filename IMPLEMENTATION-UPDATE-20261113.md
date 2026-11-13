# CRYSTAL INVESTMENTS — investor and admin update

## Included in this update
- Investor referral panel is available from the dashboard and its own navigation item.
- Admin referral manager is available in the management centre and respects the assigned `referrals` permission.
- Investor account overview reads balances from a Supabase RPC: available balance, active investment capital, accumulated interest and total account value.
- Daily accrual is requested from Supabase when the account overview refreshes; the database keeps one accrual per allocation and day.
- Deposits and withdrawals appear together in the investor transaction history.
- Approved deposits create a credit in the investor ledger. Approved withdrawals create a debit, after checking the available balance. Status, ledger entry and audit event are committed atomically.
- M-Pesa and bank transfer deposit request options are present. The M-Pesa form captures the phone number; an actual STK push still requires Safaricom Daraja credentials, callback URL and provider verification.
- Admin financial requests, investor profiles, allocation records and audit activity are read from Supabase.
- Investment allocation management reads and writes Supabase records. Approved allocations can be activated; only active allocations accrue interest.
- The global annual rate is enforced as Supa Admin-only in the database and requires MFA (AAL2). It is used for all active investor allocations.
- Junior administrator permissions can be assigned and edited by Supa Admin. Promotion, demotion and removal remain database-controlled; the last Supa Admin cannot be demoted or removed.
- Admin conversations remain restricted to administrator accounts. Website contact enquiries are stored in the support inbox.
- No new development/backend-status messages were added to investor-facing pages.

## Supabase migration order
The expected migration sequence for this project is:
1. `202611110001_initial_investor_profiles.sql`
2. `202611110002_referral_program.sql`
3. `202611110003_central_backend_and_referral_admin.sql`
4. `202611120004_interest_support_and_admin_controls.sql`
5. `202611120005_contact_admin_security.sql`
6. `202611130006_financial_ledger_and_account_balances.sql`

Do not run `202611110002_financial_and_admin_foundation.sql` on this migration path. It is an alternate schema foundation with the same numeric prefix and different table definitions.

## External payment requirement
The website now captures M-Pesa and bank deposit requests and stores them in Supabase. The request form does not itself send a Safaricom STK push. That requires an approved Daraja integration, production credentials, callback/webhook verification and reconciliation testing. Do not describe a prompt as sent until the provider confirms it.

## Verification
Changed TSX files passed TypeScript transpilation/syntax checks. A full Next.js production build was not verified because `npm install` timed out in this environment. Apply the migration in a Supabase staging project first, then run the Vercel deployment build and test with test accounts before production use.
