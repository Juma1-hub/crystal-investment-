# CRYSTAL INVESTMENTS — PWA and administrator setup

## PWA installation
The application now includes a web manifest, app icons, a service worker, an offline fallback and a dismissible install suggestion.

- Deploy over HTTPS (Vercel provides HTTPS on deployed domains).
- Open the website in a supported browser.
- On supported Chromium browsers, use the **Install app** button when the browser makes the install prompt available.
- On iPhone/iPad Safari, use Share → Add to Home Screen.
- The offline page is informational only. Investor/admin pages and financial data are not cached for offline access.

The install suggestion is not a push-notification system. Web Push requires VAPID keys, a server-side subscription endpoint, a secure subscription store, and a trusted push sender. Do not add VAPID private keys to `NEXT_PUBLIC_*` variables or browser code.

## Supa Admin and Junior Admin
1. Sign in using the existing Supabase Auth account.
2. The public header calls `crystal_admin_access()`; an active administrator sees **Admin Panel**.
3. Supa Admin opens the administrator access module.
4. Appoint an existing registered user as Junior Admin. The new Junior Admin initially has no module permissions.
5. Select the Junior Admin and tick only the modules they need.
6. Save permissions. Supabase AAL2 MFA is required; the database RPC validates the role, keys and values and writes an audit record.
7. Untick permissions and save to revoke them. The database permission function is checked on protected calls, so the UI is not the security boundary.
8. Supa Admin can promote, demote or remove administrator access. Database safeguards protect the last Supa Admin.

The permissions UI requires the new migration `202611150001_admin_permissions_and_access_hardening.sql` to be applied after a live-schema/migration-history review.

## Supabase migration safety
Do not execute the new migration until the actual project migration history and schema are reviewed. The repository contains a duplicate `202611110002` version prefix, and the legacy financial foundation has been reported as applied. Do not reset the project or delete existing data.

Never put a Supabase service-role key, database password, Daraja secret or VAPID private key in browser code, GitHub, or chat.
