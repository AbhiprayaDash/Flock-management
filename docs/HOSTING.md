# Hosting and free-tier review

Checked official documentation on **9 November 2026**. These are published limits, not reserved capacity or a guarantee of future free service. Check the account dashboard before deployment.

| Service | Published allowance / compatibility | Practical limit |
|---|---|---|
| [Supabase Free](https://supabase.com/pricing) | 500 MB database, 1 GB file storage, 5 GB egress + 5 GB cached egress, 50,000 monthly active users, 2 active free projects | Free projects can pause after a week of inactivity. Photos consume storage and bandwidth quickly. At 5 MB/photo, 1 GB holds only about 200 images before metadata/other files. Set a retention policy and independent backups. |
| [Cloudflare Workers Free](https://developers.cloudflare.com/workers/platform/limits/) | 100,000 requests/day, 10 ms CPU/request, 128 MB memory, 3 MiB compressed Worker | OpenNext is compatible with Next.js 16 and latest Next.js 15 minors. Dynamic requests can hit CPU limits even when waiting on external APIs is not CPU time. Actual package size and execution must be validated; compatibility is not a performance guarantee. |
| [OpenNext Cloudflare](https://opennext.js.org/cloudflare) | Next.js Node.js runtime via Cloudflare `nodejs_compat`; API routes supported | This source includes the adapter and Wrangler configuration. Do not use static Pages export for the authenticated APIs. Supabase uses HTTP, not raw PostgreSQL TCP. |
| [Vercel Hobby](https://vercel.com/docs/plans/hobby) | Next.js supported, personal non-commercial use only | A working commercial poultry farm must use a plan whose terms permit commercial use. Do not describe Hobby as universally free hosting for this app. |
| [Gemini API limits](https://ai.google.dev/gemini-api/docs/rate-limits) | Provider/project/model-specific free allowances may exist | Check the provider console. Free allowance is not an unlimited or permanent entitlement. Image calls have separate support/limits; this implementation provides text AI only. |

Supabase stores private originals; the application requests five-minute signed URLs. Downloads and signed accesses consume the storage provider's transfer quota. No image resizing proxy or public CDN is used. Original photos are capped at 5 MB each.

AI is optional and separately billed by the configured provider. No provider-independent "free AI" allowance exists. Rules work without any API subscription. Configure provider-side spending ceilings. The application reserves ten requests/organization/day and caps text output at 1,200 tokens; that is not an exact currency budget.

Set public Supabase variables before building. Set private AI values in Worker/Vercel secrets. Do not commit production environment files. Deployments should use HTTPS and Supabase Auth redirect allowlists.
