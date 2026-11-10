# Implementation status

## Implemented in source

- Responsive dashboard and multiple farm/shed/batch setup, explicit demo label and browser persistence.
- Supabase email/password login, confirmation/reset request, password update, invitations accepted on matching email, organizations and roles.
- Database RLS, worker shed assignments, private bucket policies, record validation, revision checks, audit for records and access edits.
- Daily log drafts/validation, additive records/corrections, inventory events, sampled weights, feed deliveries, environment observations.
- Derived inventory/feed/water/weight/FCR/ADG/density and data completeness; missing inputs suppress relevant metrics.
- Editable example feed/lighting/pH/ammonia profiles, stage timeline, vaccine records, checkpoint records, health cases, treatment/withdrawal register.
- Private image upload/signed access/deletion with Supabase configuration; demo deliberately does not upload.
- Optional server-side text AI with consent/quota/JSON validation/fallback; no invented image results.
- CSV and printable batch summary, Next.js build, Cloudflare/OpenNext and Vercel setup instructions.

## Incomplete acceptance criteria / production work

- Manager/veterinarian assignment scope is organization-wide; only workers are shed-scoped. Assignment management and full team/audit UI are pending.
- Database migrations and live policies have not been executed in a Supabase project here. The opt-in isolation/storage test requires credentials. Browser/mobile interaction QA is pending because the environment lacks callable browser-control tools.
- Structured AI image assessments, model adapters for images, durable AI assessment/human-review records and image quality checks are pending. Images are stored separately; capture category/timestamp/context are currently manual notes.
- Comprehensive alert lifecycle/deduplication/history, configurable threshold UI, notification delivery, checkpoint recurrence, per-day aggregation and full same-age batch comparison are pending. Attention cards show scheduled pending records.
- Validated breed/age/season performance curves, weighted biological quality scoring, confidence models, individual-weight input, matched-period consumption-per-bird, feed days remaining and full end-of-batch financial reporting are pending. No placeholder quality score is shown.
- Profiles have example values only; temperature/humidity require an approved housing profile. The lighting example is not a legal or strain-specific target. No sourced breeder dataset is redistributed.
- Structured treatment administrations/partial-cohort withdrawal tracking, marketing enforcement, paired atomic transfers and full inventory event reversal are pending.
- API validation is strongest for logs, batches, inventory and treatments; additional database domain constraints and payload limits should be added before exposure to untrusted clients. Storage enforces MIME/size claims; image byte-level decoding/malware scanning is pending.
- Dialog keyboard trapping, full screen-reader audit, end-to-end mobile/offline tests, retention automation, full PDF contents, standards/source administration, and automatic backup scheduling are pending.
- Vercel is connected to Supabase with private storage and organization policies. Clinical validation, browser QA, an AI provider and full production commissioning remain pending.


## Contract farming update

Implemented direct Farm → Shed → Batch browsing with active/completed filters, company pickup register and contract fields, and a persistent daily SOP checklist on the dashboard. Company pickups are explicit inventory removals, not farmer sale transactions. Company receipts and pickup biomass appear in reports. Historical sale events remain supported for compatibility. SOP history is saved as audited checkpoint records with one task per batch/date; completed batches are read-only in the SOP interface. Database migration 002 is required for live persistence and concurrency protections.


## Compact daily records and trend ratings

Implemented essential-only entry with immediate rule-based preview, a row for every flock day, summed same-day readings, per-day rating explanations, authorized server-side AI after saving, fallback and evidence-sensitive invalidation. Optional migration 003 plus a server-only writer enables shared AI result storage; without that configuration model ratings are device-cached. Generic health case AI review remains separate. Supabase is connected. The private flock-photos bucket has been created with 5 MB limits and JPEG/PNG/WebP restrictions. After explicit user approval, FlockWise migrations and RPC hardening were applied and production Vercel values configured. The app now supports real login/shared records/private uploads; user-authenticated end-to-end upload testing remains pending.

## Single-day and image assessment enhancement

Implemented sourced age-window targets, reporting periods, per-opening-bird intake, separate performance/completeness/severity, immediate mortality warnings, matched-period history, target-sensitive cache invalidation, readable evidence summaries and dashboard early warnings. Added Gateway/OIDC configuration, capped provider requests with fallback, and authorized private-photo triage saved as health cases. The Gateway connection must pass a live probe; account verification/credits cannot be assumed. A physician/veterinarian must review model findings. Shared daily AI caching still needs the optional server writer credential.

Live production verification on 10 November 2026 reached Gateway but returned `customer_verification_required`. AI remains unavailable until the Vercel account completes its verification/payment-method setup. Rules remain operational. No clinical data was transmitted in the synthetic probe. The temporary generation probe was removed after testing. Latest validation: 58 tests passed, one opt-in test skipped; production build passed. See DAILY-PERFORMANCE-AI.md for setup and limits.
