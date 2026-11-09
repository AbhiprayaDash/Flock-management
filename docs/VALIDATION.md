# Verification — 9 November 2026

- `npm test`: 8 passed, 0 failed, 1 skipped (live Supabase isolation/storage test needs disposable user credentials).
- `npm run typecheck`: passed.
- `npm run build:cloudflare`: passed with Next.js 16.4.5 and OpenNext Cloudflare 1.20.16; includes optimized Next.js production build.
- `npx wrangler deploy --dry-run --outdir work/worker-dry-run`: passed. Compressed Worker 1,187.22 KiB (about 1.16 MiB), below the currently published 3 MiB Workers Free limit. This does not test per-request CPU quota or live network behavior.
- `npm audit --omit=dev`: zero vulnerabilities reported at validation time.
- Source pushed to the supplied GitHub repository's `main` branch.
- No browser QA: this environment did not expose a callable `cua_repl.js` browser-control tool; per managed preview guidance no alternate browser was installed or improvised.
- No Supabase migration execution, live Auth/Storage tests, Cloudflare production deployment or veterinary validation: no external project/account configuration was supplied.

See `STATUS.md` for functional gaps. Passing build/unit checks does not make this source a fully commissioned production system.

## Contract farming, SOP and navigation update

- `npm test`: 20 passed, 0 failed, 1 live Supabase integration test skipped for missing credentials.
- New tests cover scoped farm/shed/batch selection, empty selection without cross-farm fallback, active/completed browsing, worker-visible references, checklist date and batch separation, age-based SOP tasks, company pickup inventory/FCR, demo upgrades, and rendered accessible controls.
- Browser control is not exposed in this managed environment; no end-to-end browser test is claimed. React server-rendering checks verify the new checklist and selectors; TypeScript and optimized builds verify compilation.
- Migration `002_contract_sop.sql` is supplied for live Supabase installations but was not executed here. The Vercel app remains explicitly demo-only until Supabase configuration is supplied.


## Compact entry, daily ratings and Supabase storage preparation

- 30 unit/rendering tests pass; 1 live Supabase isolation test awaits the app schema and test accounts.
- Next.js production build and type checks pass.
- Tests cover direct/legacy consumed feed, multiple entries, missing/zero readings, daily baselines, escalation and anti-downgrade rules, correction invalidation, batch isolation, empty days, and the compact form.
- Supabase private bucket created successfully. Full schema application was rejected by automatic approval review pending explicit database/security approval; no unrelated public tables were modified. Live login/upload/isolation tests are not claimed.


## Connected Supabase verification

After the user approved full setup, migrations 001–004 applied successfully to `mhcnpjopukekudvmduzu`. The bucket is private, max 5 MB, JPEG/PNG/WebP only. All new application tables have RLS. Transactional real-database tests passed own access, foreign-org record read/edit/insert denial, foreign-photo read/insert denial, log corrections plus audit, and denial of client-written AI caches; all test fixtures rolled back. Production Vercel URL and publishable-key variables are set. No service-role key or AI provider key was configured. Auth URL settings and a real-user browser/upload test remain outside this verification.

## Signup and recovery repair

Auth logs confirmed repeated signup for an already confirmed email, plus an invalid-password sign-in; signup was not disabled and no Auth service health issue was reported. The UI now gives accurate existing-account guidance, supports confirmation resends and a dedicated recovery form, handles connection failures without a stuck button, and allows existing shorter passwords at sign-in. Recovery intent is captured before the SDK consumes the URL hash. Passwords are never trimmed, logged, overwritten by signup or changed without an authenticated recovery submission. Targeted mocked client and rendered UI tests verify these flows; no real reset email or password change was initiated by the agent.


## Immediate signup preparation

The UI now requests only email/password and removes confirmation-resend controls. A live read of `/auth/v1/settings` still reported `mailer_autoconfirm=false`; the integration cannot update this setting. Signup is gated by a fresh settings check until the administrator disables confirmation. Native returned sessions enable immediate access. Private invitation-token migration was applied and transactionally verified: email-only grant blocked, legacy RPC blocked, wrong/reused tokens blocked, valid token accepted. No existing passwords were changed and no verification requirement is falsely reported as disabled.
