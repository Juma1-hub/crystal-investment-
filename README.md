# CRYSTAL INVESTMENTS

Corporate website and investor portal frontend for CRYSTAL INVESTMENTS.

## Technology
- Next.js 15
- React 19
- TypeScript
- Tailwind-free custom CSS
- Lucide icons

## Routes
- `/` — corporate homepage
- `/about`, `/divisions`, `/opportunities`, `/portfolio`, `/approach`, `/global-presence`, `/insights`, `/contact`
- `/login`, `/register`
- `/investor` — individual investor account overview
- `/investor/investments`
- `/investor/deposits`
- `/investor/withdrawals`
- `/investor/transactions`
- `/investor/documents`
- `/investor/profile`

## Local development
```bash
npm install
npm run dev
```

## Production build
```bash
npm run build
```

Investor portal screens are frontend interfaces. Authentication, identity verification, account data, financial ledger, payment processing and permission enforcement must be connected to the production backend before live investor account use. Do not enter or accept live funds through unconnected frontend forms.
