# CRYSTAL INVESTMENTS — security and connection checklist

## Supabase migration

Apply SQL in this order in the Supabase SQL Editor:

1. `202611110001_initial_investor_profiles.sql` (already reported successful).
2. `202611110002_referral_program.sql` (already reported successful).
3. `202611110003_central_backend_and_referral_admin.sql`.
4. `202611120004_interest_support_and_admin_controls.sql`.
5. `202611120005_contact_admin_security.sql`.
6. `202611130006_financial_ledger_and_account_balances.sql` (includes a targeted drop/recreate of the existing `admin_list_investment_allocations()` RPC because its OUT-column return type changed).

**Do not run `202611110002_financial_and_admin_foundation.sql` on top of this migration path.** It is an older alternate schema with overlapping table names and a different admin-membership model. Applying it can create schema conflicts.

Run each remaining migration once, in order. Keep the SQL Editor success result and check the Supabase table list afterwards.

## Administrator access and MFA

- The admin workspace checks the signed-in Supabase account against `crystal_admin_memberships`.
- Active Junior Admins see only modules granted in their permission map.
- Only Supa Admins can manage administrator roles or annual interest rates.
- The last active Supa Admin cannot be demoted or removed.
- Every administrator must enrol an authenticator app (TOTP) before accessing the admin workspace.
- Rate changes and administrator role changes require an AAL2 session; the database rejects the action if MFA has not been verified.
- Supa Admin can appoint/promote/demote/remove roles. Role changes are written to the audit log.

In Supabase Dashboard, enable **Authentication → Multi-Factor Authentication → TOTP**. Require verified email addresses and configure strong password policy. Keep recovery codes securely offline. Do not share the Supabase service-role key or database password with the browser.

## Contact and administrator conversations

The public contact form writes to `crystal_support_messages` through a rate-limited database function. Enquiries are visible in the administrator Support Inbox. The contact function limits repeat submissions from the same email address; also enable Supabase CAPTCHA protection in Authentication settings before opening the site publicly.

The administrator conversation area is restricted by database policy to active administrator memberships. It is not visible to investor accounts.

## Exchange rates

The investor dashboard retrieves current KES-based rates from the exchange-rate service and refreshes its in-memory cache hourly. The selected display currency changes how amounts are shown; stored balances, allocations and transactions retain their original currency. If rates are unavailable, converted amounts display as unavailable rather than inventing a rate. The exchange-rate timestamp is available on each converted amount by hovering/tapping its value.

## Payment and financial controls

Deposit and withdrawal forms submit authenticated requests to Supabase. They do not execute payments or transfer funds. Payment execution, reconciliation, investor allocation activation and withdrawal settlement must be connected to an approved provider and authorised operating arrangements before live use. Approval of a request alone must not be treated as a completed transfer or an activated investment.

Annual rate accruals are recorded in the database against active allocations. The rate entered by Supa Admin must match the relevant signed opportunity/investor terms and must not be described as guaranteed returns unless legally approved.

## Before public launch

- Configure SMTP and email confirmation.
- Enable CAPTCHA and review Auth rate limits.
- Review RLS policies and test with separate investor, Junior Admin and Supa Admin accounts.
- Verify TOTP enrolment, role escalation, last-Supa-Admin protection and audit logs.
- Configure backups, monitoring, alerting and incident recovery.
- Complete legal and regulatory approvals, payment-provider onboarding and independent security review.
