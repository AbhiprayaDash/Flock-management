# FlockWise

A Next.js 16 / TypeScript poultry management application for broiler farms. Uses Tailwind CSS, Supabase Auth/PostgreSQL/RLS/private Storage, and an optional server-only OpenAI-compatible text provider.

**Delivery status:** runnable core implementation, not a fully commissioned farm system. Demo works without services and is visibly labeled. Production requires a Supabase project, migration, Auth URLs and deployment secrets. The connected deployment uses real login and private storage. Read [known gaps](docs/STATUS.md) before production use.

## Run

Requires Node 22+ and npm.

```sh
npm ci
cp .env.example .env.local
npm run dev
```

Open `http://localhost:3000`. Empty Supabase variables select demo mode. Demo examples are generated relative to the current date, are never mixed into a production organization, and persist in browser localStorage. Reset demo restores the examples. Do not enter real farm or health information in demo mode.

## Connect Supabase

1. Create a Supabase project. Execute `supabase/migrations/001_core.sql` then `002_contract_sop.sql`, then `003_daily_ratings.sql` and `004_rpc_permissions.sql` once, in that order using the SQL editor (or your migration runner). It creates organization membership, shed assignments, records, audit, invitations, AI quota tables and private storage policies.
2. Copy the project URL and **anon/publishable** key into `.env.local`. User records and photos always use the caller’s JWT. An optional server-only service-role key is supported solely for writing the shared AI-rating cache after batch authorization; never expose it as a public variable.
3. Enable email/password Auth. Set Site URL and allowed redirect URLs to the local and production origins. Configure SMTP for reliable confirmations and password resets.
4. Restart the app, create an account, confirm its email, and sign in. In Settings, create an organization, then farm, shed and batch. Placement is flock day 1 in the batch's IANA timezone.
5. Create invitations in Settings. They expire in 7 days and are accepted by a signed-in, confirmed user with the exact email. This workflow does **not** send an invitation email. Share the ordinary app URL yourself.
6. Assign workers to sheds using `public.assignments` in the SQL editor. Use UUIDs from memberships and shed records. No service key is needed in the application.

Owner manages records and membership. Manager manages organization records except treatments/profiles. Worker can submit logs, checkpoints and health cases only for assigned sheds. Veterinarian can review organization health records and author treatments/vaccinations. Viewer reads organization records. **Manager and veterinarian access is currently organization-wide, not assigned-farm scope.** Use separate organizations to partition these users pending finer assignment support.

## Checks

```sh
npm test
npm run typecheck
npm run build
npm run build:cloudflare
```

Unit tests cover missing versus zero, inventory, partial harvest biomass, corrections, withdrawal dates, flock days and rule fallback. The cross-organization integration test is skipped unless the environment contains Supabase variables and `TEST_USER_A_EMAIL`, `TEST_USER_A_PASSWORD`, `TEST_USER_B_EMAIL`, `TEST_USER_B_PASSWORD` for two confirmed, disposable accounts. Do not run it against production; it creates an organization and audit records. A skipped test does not verify live isolation.

## Deploy

Recommended compatible option for a commercial farm: **Cloudflare Workers with OpenNext**, not a static Next.js export. Server APIs must remain server-side. Configuration is in `open-next.config.ts` and `wrangler.jsonc`.

1. Authenticate Wrangler in your deployment environment (`npx wrangler login`), or set a scoped Cloudflare API token in CI.
2. Set the two `NEXT_PUBLIC_SUPABASE_*` variables **at build time** (Next.js inlines public values). Store optional AI secrets as Worker secrets, never public variables.
3. `npm run build:cloudflare`, then `npm run deploy:cloudflare`.
4. Add the resulting HTTPS origin to Supabase Auth URL configuration. Test confirmations and reset redirects.
5. Set `AI_API_KEY`, `AI_MODEL`, optionally `AI_BASE_URL` with `npx wrangler secret put NAME`. Deploy/restart after configuration changes.

Vercel is also compatible: import this GitHub repository, choose Next.js, configure the environment variables and deploy. **Hobby is restricted to personal non-commercial use; a commercial farm must select a permitted plan.** The application is hosted on Vercel at https://flockwise-beige.vercel.app with Supabase Auth, organization records and private photo storage connected. Local runs without Supabase variables still use labeled demo mode. GitHub is not connected to Vercel; source deployments are currently made through the Vercel API.

See [free-tier review](docs/HOSTING.md), [administrator guide](docs/ADMIN.md), [AI setup](docs/AI.md), [calculations](docs/CALCULATIONS.md), and [remaining work](docs/STATUS.md).


## Contract farm workflow

The company handles selling; the farmer manages flock care and records company collections. Use **Company pickups** to record actual collection date, birds, mean weight, collecting company, receipt, vehicle and supervisor. Pickups reduce inventory and their biomass is included in FCR. No company chicken-sale price is treated as farmer revenue. Optional growing-charge terms are stored on the batch; no unverified settlement is calculated.

Use the **Farm → Shed → Batch** selectors on every screen to browse active and completed batches. A farm or shed without matching batches shows an empty state. Batch setup enforces the shed’s parent farm.

The dashboard’s **Daily SOP checklist** saves completion per batch and local date. The example checklist follows flock age; the company-approved SOP takes precedence. The date picker allows review of earlier days. Completed batches show read-only SOP history. Unticking a task reopens it and does not erase its database audit. Checklist ticks never replace measured daily log readings.

Existing Supabase installations must apply `supabase/migrations/002_contract_sop.sql` before using this release. This migration adds company pickup validation, batch/farm consistency and a unique index preventing duplicate SOP tasks for a batch/date. Historical sale events remain readable and are not rewritten. No live database migration was run in this session.


## Fast daily entry and per-day ratings

Daily entry now asks only for date, feed **consumed**, water intake, deaths, culls, optional average weight and notes. Advanced readings already saved remain intact. Existing offered-feed records are converted to consumed feed for display without changing their history. New consumed values are never reduced a second time by old remaining/wastage values.

The **Daily records** table contains each flock day, including gaps. Same-day entries are summed; incomplete inputs remain blank. Ratings update from transparent rules as you type; after saving a daily record an authenticated installation requests an optional AI assessment of that day and its preceding three calendar days. Results have a rating column, explanation, evidence IDs, limitations, model and timestamp. Corrections invalidate dependent cached ratings.

No key means rule-based guidance, not pretend AI. Configure the existing AI server variables and organization consent for AI. `003_daily_ratings.sql` creates a read-only-to-clients rating cache. An optional `SUPABASE_SERVICE_ROLE_KEY` lets the server persist generated ratings after authorization; without it AI ratings stay in a device-local cache. The server role key is never used to read user records or photos and never sent to browsers. Ten AI requests per organization/day are shared with other assessments. Ratings are advisory trend flags, not diagnostic probabilities, prescriptions or biological quality grades.


## Upload flock pictures

Sign in, create your organization/farm/shed/batch in Settings if needed, then select that batch and open **Photo checkpoints → Upload image**. JPEG, PNG and WebP are accepted up to 5 MB. The `flock-photos` bucket is private; signed viewing links expire after five minutes. Owners can delete photos. Anonymous users and users from other organizations cannot read the originals. The production project is now connected; the sample browser data was not imported into the real database.

Supabase Auth email/password signup and confirmation policy remains controlled by the project settings. Ensure the live origin is configured under [Auth URL configuration](https://supabase.com/dashboard/project/mhcnpjopukekudvmduzu/auth/url-configuration). The Supabase integration exposes database/storage migration tools but not an Auth URL configuration tool, so that setting was not changed from this session.
