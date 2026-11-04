# CRYSTAL INVESTMENTS — implementation notes

## Changes in this revision

- Added a custom geometric crystal SVG mark and applied it to the public header, footer, investor portal and admin console.
- Added home-page scroll reveal effects with reduced-motion support.
- Added sector-specific photographic backgrounds to the home-page division cards and investment division detail pages.
- Updated header and footer investor actions to show Investor's Dash and Log out after a session is active.
- Added a required Terms & Conditions acceptance checkbox to registration and created a Terms & Conditions page.
- Added a potential partner/institution section and a separate regulatory reference section in the footer. Names are presented as potential relationships/reference institutions only; no affiliation, partnership, licence or endorsement is claimed. The displayed marks are typographic identifiers, not official supplied logo artwork.
- Expanded the admin navigation with market conditions, platform settings and system diagnostics sections.
- Added admin investment allocation workflow: an allocation must be covered by approved deposits net of approved withdrawals and existing allocations; it then moves through Pending approval, Approved and Active.
- Added daily and cumulative simple-accrual estimates to the investor dashboard. Accrual begins only after an allocation is activated and uses the recorded annual rate and 360/365 day-count basis. Multiple currencies are kept separate.
- Added source, timestamp and sentiment fields for administrator-published market observations.
- Added clearly labelled illustrative portfolio examples in the admin portfolio area.
- Corrected monthly contribution chart grouping so currencies are not combined and each currency is scaled separately.

## Important platform limitations

This repository currently has no configured server-side authentication, database, payment integration, market-data API, secure document store, or backend authorization policies. The current account, admin, market and investment records still use browser local storage. Therefore:

- Admin role changes and admin controls are not secure production access controls.
- Investor passwords are not securely validated by a server.
- Records are not shared across devices or users and are not authoritative financial ledgers.
- Market observations are administrator-entered, not a live market feed.
- Income figures are browser-calculated estimates based on the entered annual rate and simple day-count formula; they are not official or guaranteed entitlements.
- Deposits and withdrawals are records only; no money is moved by this interface.
- Contact form delivery is not connected to an email or CRM service.

Do not use this frontend-only workflow to accept, custody, allocate or promise investor funds or returns. Production use requires secure backend implementation, legal/regulatory review, verified project terms, payment/custody arrangements, audit controls and server-side authorization.

## Revision 2 — dashboard, layout and admin controls

- Investor dashboard currency selection now drives dashboard totals, daily income, accrued income, available balance, investment rows and transaction amounts. Cross-currency display uses indicative live KES-base rates from open.er-api.com; if rates are unavailable, cross-currency values are shown as unavailable rather than mislabelled or silently treated as the selected currency.
- Added a Home destination to the investor dashboard, including the expanded mobile navigation.
- Removed the explanatory sub-lines beneath the dashboard balance metrics.
- Reworked investor dashboard colours to a light neutral palette and improved mobile navigation, spacing, responsive metric sizing and overflow handling.
- Replaced the partner and regulator text marks with compact circular organization-domain icons. Removed the explanatory paragraphs beneath these logo sections; section headings remain neutral and do not state that the organizations are partners or that any regulator has approved the company.
- Reduced image brightness through stronger overlays and lower image quality settings; replaced the mining image with a mining-specific photograph.
- Removed visible sequence numbering from public investment/process cards and changed public feature cards to open, border-light editorial layouts.
- Added working browser-workspace forms for Platform Settings and Website Content. Saved settings update the public footer; saved homepage, about and opportunities copy updates those pages.
- Investor registration now reads the default account currency from Platform Settings.

### Scope and verification notes
- Admin settings/content and investor records remain browser-local because this project revision has no connected production database or secure server-side admin service. They do not synchronize across devices or users. This revision does not make the admin workspace a secure production control plane.
- Currency conversion is indicative and depends on the external exchange-rate endpoint being reachable. It is not an accounting or settlement rate; official financial records should retain their original transaction currency and authoritative rates.
- Partner/regulator marks are loaded from the organizations' domain favicons through Google's favicon service; they are not downloaded high-resolution trademark master files. The neutral section labels avoid claiming endorsement or licensing.
- Production build was not run: dependency installation timed out in this environment. TypeScript/JSX transpilation syntax check passed for all source files.
