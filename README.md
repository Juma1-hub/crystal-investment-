# Crystal Investments — Stage 3 Administration Centre

This update adds the Stage 3 admin management centre at `/admin`.

## Included modules
- Management overview and pending-action counts
- Investor records
- KYC and compliance review queue
- Investment opportunities
- Investments and portfolio records
- Deposit approvals
- Withdrawal approvals
- Distributions
- Team and branches
- Reports and CSV audit export
- Website content shortcuts

## Current implementation boundary
The admin workspace is a frontend-stage implementation. Its working records and review actions are stored in the current browser's local storage. It is not secure administrator authentication, a shared database, a KYC document vault, a payment processor, or a financial ledger. Do not use it to approve or execute real-money transactions. Stage 4 connects this interface to Supabase with server-side authentication, role-based access, database policies, audit logging, and validated financial workflows.

## Access
Open `/admin` on the deployed site to inspect the Stage 3 interface. A secure admin sign-in and role restriction are part of the backend integration stage and must be completed before production use.
