# FlockWise

A Next.js 16 / TypeScript poultry management application for broiler farms. Uses Tailwind CSS, Supabase Auth/PostgreSQL/RLS/private Storage, and an optional server-only OpenAI-compatible text provider.

**Delivery status:** runnable core implementation, not a fully commissioned farm system. Demo works without services and is visibly labeled. Production requires a Supabase project, migration, Auth URLs and deployment secrets. Read [known gaps](docs/STATUS.md) before production use.

## Run

Requires Node 22+ and npm.

```sh
npm ci
cp .env.example .env.local
npm run dev
```

Open `http://localhost:3000`. Empty Supabase variables select demo mode. Demo examples are generated relative to the current date, are never mixed into a production organization, and persist in browser localStorage. Reset demo restores the examples. Do not enter real farm or health information in demo mode.

## Connect Supabase

1. Create a Supabase project. Execute `supabase/migrations/001_core.sql` once using the SQL editor (or your migration runner). It creates organization membership, shed assignments, records, audit, invitations, AI quota tables and private storage policies.
2. Copy the project URL and **anon/publishable** key into `.env.local`. Never give this app a service-role key; it uses the caller's JWT for all operations.
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

Vercel is also compatible: import this GitHub repository, choose Next.js, configure the environment variables and deploy. **Hobby is restricted to personal non-commercial use; a commercial farm must select a permitted plan.** No deployment has been performed by this source checkout; no hosting account or Supabase project credentials were provided.

See [free-tier review](docs/HOSTING.md), [administrator guide](docs/ADMIN.md), [AI setup](docs/AI.md), [calculations](docs/CALCULATIONS.md), and [remaining work](docs/STATUS.md).
