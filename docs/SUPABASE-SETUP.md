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

**Approval state:** automatic approval review rejected the full migration because the latest authorization named private storage, not broad database/RLS changes. The bucket-only action succeeded. Explicit user approval of the listed full database/security changes is required before continuing that migration. The live app remains in demo mode meanwhile.
