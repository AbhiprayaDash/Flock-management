# Supabase connection plan

Selected project: AbhiprayaDash’s Project (`mhcnpjopukekudvmduzu`).

Completed: inspected existing public tables and storage; created **private** `flock-photos` bucket, max 5 MB, JPEG/PNG/WebP only. No pre-existing public tables were modified. No unrestricted photo policies were added.

The existing project has a different farm application schema (`farms`, `flocks`, `daily_logs`, and others). FlockWise uses separate names and does not overwrite them.

To enable this app’s secure uploads and shared records, the prepared migrations add:

- `001_core.sql`: organizations, memberships, shed assignments, records, audit, invitations, quota tables; row-level access rules, record/inventory validation, audit triggers and authenticated private photo policies. Existing private bucket creation is skipped.
- `002_contract_sop.sql`: company pickup validation, farm/shed checks and unique per-batch/day SOP records.
- `003_daily_ratings.sql`: authorized read-only AI-rating cache, worker AI quota participation and consumed-feed validation. Shared AI-cache writes require a separately configured server-only key; private photos do not.

After migration: verify RLS and storage policies, set the project URL and publishable key as the app’s Vercel environment variables, and rebuild. No service-role key is required for normal login, records or uploads. The app will then use login rather than browser demo data. Existing demo records are not imported automatically.

Supabase Auth Site URL and allowed redirects must include `https://flockwise-beige.vercel.app` for email confirmation and password reset. This is an Auth dashboard setting, not a database SQL setting.

**Current state:** user explicitly approved the full setup. Migrations 001–003 and RPC permission hardening (004) were applied successfully. Production Vercel variables now contain the Supabase URL and publishable key; no service-role key was installed. The redeployed app uses real login, shared records and private uploads. Existing unrelated tables are retained.

Live transactional tests passed for own-batch access, cross-organization record reads/edits/inserts, private photo metadata isolation and unauthorized uploads, audit history and protection against client-written AI ratings. All fixtures were rolled back. This tests database/storage access policies; a real-user end-to-end photo upload still requires signing into the app.

The Supabase security advisor reports the new helper/API RPCs are callable by authenticated users by design. Trigger-only functions and anonymous RPC access were explicitly revoked. The no-policy `ai_usage` table is intentionally accessible only through its authorized security-definer quota function. Existing unrelated `flockbook_*` function warnings were left unchanged. Review the [existing function search-path notices](https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable) and [password protection settings](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) separately.

AI provider credentials are not configured. Daily ratings therefore remain clearly labeled rule-based guidance until provider setup and organization consent are complete.
