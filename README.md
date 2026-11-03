# Crystal Investments — Stage 3 Admin Analytics & Roles Update

This update extends the Stage 3 admin workspace with:
- Analytics for approved contribution and withdrawal records, separated by KES, USD and GBP.
- Contribution activity bar graph and investor-level contribution/withdrawal/net recorded cash balance table.
- Investor profile editing for registered profiles available in the current browser workspace.
- Supa Admin / Junior Admin role-management interface: appoint junior admins, promote or demote admins, and remove admin entries.
- Deposit and withdrawal approval decisions are synchronised with the corresponding browser-stored investor records.

## Important limitations
This is still a frontend/browser-storage prototype. Browser localStorage is isolated per browser/device and is not a central site database. The dashboard can only analyse records present in the browser where it is opened. Role changes are not security controls: there is no verified administrator sign-in, server-side role enforcement, or Supabase Row Level Security yet. Do not use it for real investor data, live balances, custody, payment execution, or financial approvals.

Amounts are shown separately in KES, USD and GBP; no exchange rates are assumed. Net recorded cash balance is calculated as approved contributions less approved withdrawals. It is not a full portfolio valuation and excludes allocations, fees, gains/losses and pending requests.

## Deploy
Replace the existing repository files with this project, commit, and allow Vercel to deploy. The admin page is `/admin`.
