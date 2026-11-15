# CRYSTAL INVESTMENTS — Implementation update (15 November 2026)

## Source used
This update was prepared from the repository ZIP uploaded in this conversation:
`crystal-investments-investor-admin-financial-update-typefix2(2).zip`.
The archive is dated 13 November 2026. It was treated as the source of truth for this update. No live GitHub repository or Supabase project was accessed.

## Implemented in this source update

### Administrator access and permissions
- The public site header now checks the signed-in Supabase session against `crystal_admin_access()` and displays an **Admin Panel** link only for an active Supa Admin or Junior Admin.
- The Admin Console continues to verify the active administrator membership through Supabase before rendering.
- Junior Admin navigation is filtered by the permissions stored in the active membership.
- Supa Admin has a permissions table with individual checkboxes grouped by module. Permissions can be ticked or unticked and saved to Supabase.
- Supa Admin can appoint a Junior Admin, promote/demote administrators, and remove administrator access. The existing database safeguards remain responsible for blocking removal/demotion of the last Supa Admin.
- Permission and role changes require AAL2 MFA and are audited by database functions.
- A new RPC, `admin_update_junior_permissions(uuid,jsonb)`, validates the allowed permission keys, validates boolean values, updates only active Junior Admin memberships and writes an audit record.
- Read access to deposits, withdrawals, investor profiles, ledger entries, audit records, site configuration, investment allocations and private admin conversations is narrowed to the relevant module permission where the migration replaces the previous broad policy.
- Private admin conversation sending now checks the explicit `admin_conversations` permission.

### PWA / installable app
- Added the Next.js App Router web manifest, application metadata and app icons (192px, 512px and maskable 512px).
- Added a service worker and a static offline fallback page.
- The service worker deliberately does not cache investor/admin routes, API responses or financial/account data.
- Added a dismissible installation suggestion. It uses the browser install prompt where supported and provides Add to Home Screen guidance for iOS Safari.

### Supabase-backed website content and settings
- The Admin Site Manager no longer stores its settings/content in browser localStorage. It reads and writes the `crystal_site_configuration` table through the existing Supabase RPCs.
- Public website text and footer settings are read through a new allow-listed RPC, `crystal_get_public_site_configuration()`. It returns only the approved public presentation fields, not arbitrary configuration JSON.
- The site configuration write RPC is tightened so `website_content` permission cannot be used to modify `platform_settings`, and vice versa.

### Financial fail-closed changes
The source contained financial workflows that were not safe to enable against the reported unreconciled database:
- The existing deposit approval RPC creates a ledger credit but does not perform the required eight-division allocation.
- The existing withdrawal approval path does not implement the approved proportional eight-division principal reduction and pending-request reservation model.
- The existing withdrawal submission RPC does not reserve funds atomically against concurrent requests.
- The prior dashboard called a daily accrual RPC when the investor opened/refreshed the dashboard, rather than relying on a verified scheduled accrual process.

To avoid creating more inconsistent financial records:
- Deposit/withdrawal approval actions are not exposed in the Admin UI in this release.
- The existing financial approval RPC, manual allocation create/update RPCs and withdrawal-submission RPC are revoked for client roles by the new migration until the safe workflows are implemented and verified.
- Manual arbitrary project allocation has been removed from the Admin UI. The portfolio screen now shows the eight fixed divisions and existing allocation records read-only.
- Investor withdrawal submission is temporarily unavailable until reservation and proportional-reduction controls are installed.
- The dashboard no longer triggers daily interest accrual itself; the old investor-triggered accrual and summary RPCs are revoked for client roles until a verified scheduled server-side accrual process is installed.
- Investor account balances and earnings are temporarily withheld in the dashboard while the reported deposit/ledger discrepancies are unresolved.
- Currency values remain in their recorded source currency unless a verified conversion source is connected; the previous direct third-party FX fetch was removed.
- M-Pesa is labelled as manual review; submitting deposit details does not claim that an STK Push was initiated or that payment was received.
- Existing records are not deleted, overwritten, reset or manually adjusted.

## New migration

`supabase/migrations/202611150001_admin_permissions_and_access_hardening.sql`

This is a forward-only migration. It does not update or delete financial records. It:
- Adds the granular Junior Admin permission update RPC.
- Adds aggregate analytics output without exposing investor-level request data to analytics-only administrators.
- Adds a public-safe site configuration reader.
- Replaces identified broad administrator read policies with module-specific checks.
- Tightens site configuration writes.
- Adds support-message archiving fields and a Supa Admin-only archive RPC.
- Revokes the old permanent-delete support RPC.
- Restricts private admin conversations by permission.
- Revokes unsafe financial client RPC access until reconciliation and correct workflows are complete.

**Do not run this migration yet.** Before applying it, inspect the live Supabase migration history and actual schema. The repository contains two different files with the `202611110002` prefix, and the legacy financial foundation was reported as already executed. Confirm the exact live objects, policies, RPC signatures, and migration history first. The new migration has prerequisite checks and will stop if required objects are missing, but that is not a substitute for the required review.

## Not completed / external prerequisites
This ZIP must not be described as a fully operational financial-services release. The following remain outstanding:

1. Read-only reconciliation of the existing approved deposits, ledger entries, allocations and withdrawals using the live schema, audit evidence and migration history.
2. A transactionally correct approved-deposit workflow that creates exactly eight allocations (12.5% each), handles rounding exactly, and records ledger entries without double counting.
3. A transactionally correct withdrawal reservation and approval workflow that locks the investor/currency account, reserves pending requests, and proportionally reduces all eight allocation principals.
4. A reliable scheduled, server-side and idempotent daily interest process with rate-history handling. Dashboard page views must not be the scheduler.
5. Complete referral commission lifecycle verification and reconciliation.
6. Actual Daraja/M-Pesa integration, provider credentials, callback verification, idempotency, reconciliation and testing. No STK push is implemented by this frontend.
7. Banking-provider onboarding/integration where applicable.
8. Full KYC, document storage, investor statements, support retention and operational controls.
9. Real web-push notifications. The app-install suggestion is implemented; push notifications still require VAPID configuration, subscription storage, a trusted server-side sender and delivery testing.
10. Legal and regulatory confirmation before any public real-money operations.

## Verification performed
- The archive was extracted and the active `app/` and `components/` source was inspected.
- TypeScript/TSX syntax transpilation was run across 85 TS/TSX files and reported no syntax diagnostics at the time of that run. Re-run after any further changes.
- `npm install --no-audit --no-fund` timed out in this environment.
- A full `tsc --noEmit` could not be completed because project dependencies and React/Next.js type declarations were not installed; it reported missing modules/types as expected in that state.
- No Next.js production build was completed.
- No SQL migration was executed.
- No live Supabase connection, database query or RLS test was performed.

## Required next engineering stage
1. Obtain a read-only inspection of the live Supabase migration history, tables, constraints, functions, triggers, policies and audit history.
2. Reconcile the existing financial records without changing them.
3. Design and test the correct deposit-allocation, withdrawal-reservation, proportional withdrawal, ledger and scheduled-interest workflows in staging.
4. Re-enable the financial actions only after those workflows pass tests and the user approves the migration.
5. Complete the remaining Supabase-backed modules, push notifications and provider integrations.
6. Install dependencies, run the full typecheck, production build and database/RLS tests, then deploy to a staging Vercel environment.
