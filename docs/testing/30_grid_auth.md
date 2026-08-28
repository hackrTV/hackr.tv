---
title: Grid Auth — Register, Login, 2FA, Identity
area: The Grid
minutes: 25
---
# Grid Auth + Account Lifecycle

Use the FRESH account for registration; the operative for 2FA/identity.

## Steps — registration (fresh account)

1. Visit `/grid/register`. → Registration form.
2. Submit with a reserved or malformed alias (spaces, symbols). →
   Rejected with a clear error (alias must be `[A-Za-z0-9_]+`).
3. Submit valid alias + email. → "Check your email" state; verification
   email arrives with a `/grid/verify/<token>` link.
4. Open the verify link, set a password, complete registration. →
   Account created; you land logged in (or at login) per flow.

## Steps — login/logout

5. Log out; log in at `/grid/login` with a WRONG password. → Rejected;
   no session.
6. Log in correctly. → Full page load (session change), logged-in nav,
   cable reconnects (live features work after).
7. **Disabled account**: admin disables the fresh account (`/root` →
   Hackrs → disable login), then try to log in. → "Account disabled"
   rejection. Re-enable.

## Steps — 2FA (operative)

8. Visit `/identity` → two-factor section → begin setup at
   `/identity/two-factor`. → QR + secret shown; add to an authenticator.
9. Enable with a valid code. → Backup codes displayed ONCE — save them.
10. Log out; log in. → Password accepted → interstitial
    `/grid/login/verify` asks for a TOTP code; wrong code rejected;
    correct code completes login.
11. Log out; log in using a BACKUP code at the interstitial. → Works;
    that code is consumed (a second use fails).
12. **Disable-during-2FA race**: with the operative at the TOTP
    interstitial (password already accepted), disable the account from
    admin, then submit a valid code. → Rejected ("disabled"), pending
    session cleared. Re-enable.
13. Regenerate backup codes from `/identity/two-factor`. → New set;
    old ones dead.
14. Disable 2FA. → Next login is password-only.

## Steps — password + email flows

15. `/grid/forgot_password` → submit the operative's alias/email. →
    Reset email arrives; `/grid/reset_password/<token>` sets a new
    password; old password stops working.
16. From `/identity`, request a password reset for the CURRENT account.
    → Same email flow.
17. Request an email change from `/identity`. → Confirmation email to
    the NEW address; `/grid/confirm_email_change/<token>` page confirms
    (form posts as a full-page submit); identity page shows the new
    email.

## Steps — identity page

18. `/identity` shows alias, role, email, session/security sections;
    all mutations above reflected. DISCONNECT logs out (player resets —
    expected full reload).
