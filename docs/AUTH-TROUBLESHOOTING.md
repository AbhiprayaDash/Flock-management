# Signup and account recovery

Supabase accounts belong to the project, not to an individual frontend. An email already registered in the same project should sign in with its existing password. Repeating signup does not change that password. Supabase intentionally returns an obfuscated successful response for some existing-account signup attempts, rather than exposing registration status.

The app now explains both paths without falsely promising a new confirmation email: new users confirm their email; existing users sign in or request password recovery. It does not auto-confirm accounts, overwrite passwords, or reveal account existence through a public lookup.

Use `https://flockwise-beige.vercel.app/?mode=reset` to open the reset request form. Enter your email and choose **Send reset link**. Open the resulting email to return to the dedicated **Choose a new password** screen; saving changes only the authenticated account. There is no need to create a second account. Existing passwords shorter than the new signup minimum can still be submitted for sign-in; new passwords need at least eight characters and matching confirmation.

The signup screen also supports **Resend confirmation** for unconfirmed accounts. Network errors release the submit button instead of leaving it stuck. Confirmation and recovery errors are shown explicitly. Requests remain subject to Supabase email limits and configured SMTP delivery.

Under Supabase Auth URL configuration, allow the production origin and `https://flockwise-beige.vercel.app/?reset=1`. Do not disable email verification or share passwords/API secrets in chat to work around login issues.

Verification: auth logs showed repeated signup responses for an already confirmed email and an invalid-password sign-in; no database failure or disabled signup. Targeted tests cover existing-account guidance, email trimming without password mutation, signup versus password update separation, recovery redirects and matching passwords, existing shorter-password sign-in and explicit recovery rendering. Real email delivery and entering a new password remain actions for the account owner; no reset email was sent by the agent and no account password was changed.


## Requested immediate email/password signup

Signup now has only email and password. Confirmation and confirmation-resend controls are removed. With Supabase **Confirm email** disabled, native `signUp` returns a session and the app opens the workspace immediately. It does not change an existing account’s password.

The connected Supabase tools do not expose hosted Auth configuration updates. Set **Authentication → Sign In / Providers → Email → Confirm email OFF** in the project dashboard. The last live check still showed confirmation enabled; this is a required remaining administrator step. The app checks the live setting before signup and does not send signup-confirmation emails while the required setting is pending.

Private invite links now authorize farm membership. Matching an invited email alone cannot add a user to an organization. Owners create an invitation and share the generated one-time link privately; recipients sign in or create an account using that link and the invited email. The old email-only acceptance RPC is revoked. A live rolled-back test verified that email alone and wrong/reused tokens cannot grant membership, while a valid token grants only the invited role.
