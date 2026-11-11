# CRYSTAL INVESTMENTS — Backend readiness checkpoint

## Work in this revision
- Preserved the existing site layout, branding, navigation and Supabase authentication/profile integration.
- Replaced investor-facing deposit/withdrawal copy that referred to future development with neutral, current account-service wording.
- Added `supabase/migrations/202611110002_financial_and_admin_foundation.sql` for financial records, allocations, ledger, distributions, documents, admin memberships, audit logs and platform settings.
- Added setup instructions and first Supa Admin bootstrap SQL to `SUPABASE-SETUP.md`.

## Administrator requirements to carry forward
- Complete the Admin Management Centre using Supabase-backed records, not browser localStorage.
- Supa Admin can appoint/remove Junior Admins, promote a Junior Admin to Supa Admin, demote a Supa Admin and remove admin access.
- Junior Admin permissions must be least-privilege and configurable/explicit; Junior Admins must not manage Supa Admin membership or bypass approval controls.
- Enforce every permission server-side with Supabase RLS / trusted server functions. Hiding buttons in the browser is not security.
- Record administrator changes in `admin_audit_logs`.
- Preserve separate KES, USD and GBP ledgers; never add different currencies without a verified conversion process.
- Payment integrations must use provider webhooks verified server-side and idempotent transaction reconciliation. Never accept a browser claim as proof of payment.

## Current limitations
- The new migration has been prepared but has NOT been run in Supabase.
- The current Admin Management Centre still has browser-storage prototype logic; the schema is groundwork, not a completed live admin integration.
- Deposit, withdrawal, allocation, distribution and ledger workflows are not yet wired to the new tables.
- Payment processing is not integrated.
- No live financial operations should be enabled before required regulatory approvals, payment-provider onboarding and backend controls are complete.
- Full Next.js production build has not been verified in this environment.
