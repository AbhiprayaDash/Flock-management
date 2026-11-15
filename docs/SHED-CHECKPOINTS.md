# Daily Shed Checkpoints & Alerts

Open **Shed checkpoints** in the sidebar after selecting a farm, shed and batch. The Overview contains a compact summary. This workflow uses Supabase storage; demo mode cannot write production checkpoints.

## Start a schedule

1. An owner or manager opens **configuration → Management profiles & farm approval**. Review the example against the actual strain, brooding method, housing, seasonal conditions, integrator/veterinary instructions and local requirements. Enter the source, version and effective date. Save an approved version only after review. The example's day bands and warning/critical/recovery margins are explicitly application examples; they are not published breeder action limits. Nothing is automatically farm-approved.
2. Open **Checkpoint schedules & staff assignments**. Select the approved profile, responsible worker and backup manager. Membership choices identify existing members by role/ID; administrators can add useful display labels without exposing Auth email addresses. Workers must have access to every shed covered by their schedule.
3. Save the editable example 06:00, 10:00, 14:00, 18:00 and 22:00, or enter custom times/intervals. The farm's timezone is authoritative. Set reminder lead, completion window, escalation delay, required fields and pH testing interval. Routine batch schedules override shed schedules, which override farm defaults. Mark additional schedules as **additional** to retain routine checks; use age/date windows for brooding and incidents. Individual extra checks are also available on the Today tab.

Scheduled and actual measurement timestamps are separate. Existing issued checks retain their assignment/profile snapshots. Changes create new schedule revisions; completed records retain history. Nonexistent daylight-saving clock times notify the manager rather than silently shifting the check. Ambiguous measurement times require an explicit UTC offset.

## Record and respond

- Staff open an available check on a mobile device. Numeric readings begin as **Not measured**, never zero. Record instrument/manual or sensor provenance, explicit estimates where permitted, or a reason for unavailable measurements/access. Ammonia cannot be estimated from smell or photos. Occasional pH tests do not become required at every check.
- Enter new feed, water, deaths and culls for the explicit interval. Water supports interval quantities, cumulative meters and explicit meter resets. Enter verified live birds if placement/movements do not establish the exposure. Overlaps, unknown bird exposure, missing intervals and incompatible baselines withhold consumption comparisons. These entries **never add to daily log totals**; daily reports remain the daily accounting source.
- Photos are private JPEG/PNG/WebP, up to six, 5 MB each. Viewing uses short-lived signed URLs. Measurements, corrections, profile versions, actions and overrides are audited.
- Rule alerts are deterministic and do not require an AI key. Critical limits act immediately. Warning persistence and distinct-measurement recovery counts/bands are configurable. Consumption compares per-bird-hour rates only against at least three recent intervals of comparable age, clock time, duration and profile. Two-hour intervals do not reuse six-hour baselines. Combined conditions include heat/humidity/panting, ammonia/wet litter/ventilation, reduced feed/water and mortality/respiratory signs.
- **Acknowledge / record action** records acknowledgment, comments, assignment or corrective actions and creates a timed recheck. Acknowledgment does not resolve a condition. Recovery measurements must meet the configured criteria; an owner/manager/veterinarian may instead enter a justified override. AI cannot resolve alerts or prescribe medication.
- **history** includes six charts, age target bands, timestamp/condition markers, corrections, CSV and browser **Print / save PDF**. Report periods include a farm-local calendar day, last 24 hours, seven days and the batch. Readings always show their measurement time/age. Feed/water charts show derived interval consumption rather than the raw cumulative meter counter.

## Offline and reminders

Opening a form stores a debounced draft in IndexedDB on that device, scoped to the signed-in account and batch. Drafts survive reload. Queue explicitly when offline; reconnect with the same account to synchronize. Retried requests/photos retain identifiers and cannot create a second reading. Conflicting corrections require review. Offline mode requires the page to have been loaded already; this is not an installable fully cached offline application. Protect shared devices and discard unwanted drafts.

In-app reminders persist even when external notification channels fail. **Enable browser push** requests permission and registers this device over HTTPS. Unsupported browsers retain the in-app fallback. Provider acceptance is labelled separately from device delivery, which cannot be confirmed by the server. Email/SMS integrations are not connected; no paid messages are sent. Any future provider needs explicit configuration and disclosure of its costs.

The deployed database evaluates checkpoints and escalation every minute through `flockwise-checkpoint-evaluate`. A separate minute job wakes the `checkpoint-worker` Supabase Edge Function. The worker requires a private random header secret, checks current farm access, allowlists push service endpoints, retries failures and disables expired subscriptions. It does not contain VAPID credentials in source. A private RLS-protected settings table holds VAPID/worker secrets; public clients receive only the public VAPID key. These secrets must never be copied into a NEXT_PUBLIC variable, committed or exported to a browser. To rotate, replace the stored key pair/worker secret, then have devices resubscribe; old subscriptions may require removal. Monitor cron job history, function logs and the notification queue for failures.

## Optional AI

**insights → Explain recent patterns with AI** uses the existing server AI provider and organization AI-sharing consent/rate limit. The input covers the latest 72 hours, at most 12 readings and six recent logs/cases, narrowed further to the request budget. Operator season/weather notes are included; an external weather service is not connected. Facts, patterns, possible explanations, checks and uncertainty are separated. Model, generation time, period and input hash are stored. Corrections mark earlier explanations as outdated. No private photo originals are sent by this text-insights action. Threshold alarms continue if the provider/key is unavailable.

## Storage, access and operation

Apply migrations `202611150001` through `202611150007` in order. The live connected project has these migrations, the Edge worker and both cron jobs installed. Enabled schedules require approved profiles; the feature deliberately does not create unreviewed farm targets or assign real workers automatically.

Clinical tables use batch/farm RLS and validated RPC writes. Internal rule state, request deduplication and push secrets intentionally have no client policies. Existing membership/assigned-shed access is reused. The API verifies the JWT and accessible batch, and the worker rechecks access before sending. Archived batches retain history.

## Verification

- `npm test`: schema validation, farm-local timezone/DST conversion, unavailable/estimated readings, IndexedDB account/batch isolation, photo retry paths and CSV escaping, alongside the existing suite.
- Run `supabase/tests/checkpoints.sql` on the connected database as a single transaction. Every assertion and fixture is rolled back. It exercises approval, assignments, thresholds/persistence/recovery, acknowledgment/actions/rechecks, missed-check escalation/deduplication, idempotency/corrections, meter resets, exposure and interval-matched baselines, no double-counting, worker permissions and foreign-farm denial.
- `npm run build`: Next.js and TypeScript production validation. Edge function deployment separately validates its Deno bundle.
- Mobile/desktop browser checks used synthetic local API fixtures: draft restoration after reload, offline queue, exactly one synchronization, correction control, viewer restrictions, no horizontal overflow or browser exceptions. Production database tests used rollback-only fixtures. A production signed-in browser journey and actual device push delivery were not asserted; persistent test-account creation was blocked by automatic approval review and no test account was created.
