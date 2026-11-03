# Crystal Investments — Investor Portal Demo

## Test the investor dashboard without a backend

1. Deploy this project to Vercel (or run it locally).
2. Open `/register`.
3. Complete the required fields and select **Submit registration details**.
4. The browser saves a sample investor profile in local storage and redirects to `/investor`.
5. To test returning access, sign out and visit `/login`. Use the same email address saved during registration and enter any password.
6. The dashboard is also directly available at `/investor`.

## Demo limitations

This is a frontend-only demonstration. The profile is stored in the current browser only. It is not sent to a server, does not create a verified investor account, and is not secure authentication. The password is neither validated nor stored. Do not enter real identity documents, passwords, banking information, or payment details. Balances and portfolio figures are illustrative and no deposits, withdrawals, or investments can be made.
