# Optional AI

Core calculations, editable example schedules and deterministic `Rule-based guidance` work with **no API key**. The fallback cites recent actual log IDs, flags high entry mortality and ammonia, and checks water decline against three previous entries. Unequal intervals and multiple entries can confound that baseline; review the recorded evidence.

Set server-only `AI_API_KEY`, `AI_MODEL` and an HTTPS `AI_BASE_URL` exposing `/chat/completions` with JSON mode. Configure organization consent in Settings. The endpoint retrieves records using the caller's JWT; it never accepts user-supplied evidence as authoritative. The provider receives recent batch log data including notes and symptoms, computed metrics and record IDs. Images, names of other organizations and secrets are not intentionally sent.

Responses must match a Zod schema. Invalid, timed-out, missing-key or failed-provider calls fall back to explicitly labeled rules. Provider model, timestamp and human-review requirement appear with live responses. System instructions prohibit prescriptions, definitive diagnoses and numerical diagnostic probabilities. Inputs are untrusted; model output is advisory, never executed as a tool or used to change records. Schema validation does not prove clinical correctness: a qualified human must review every response. Severe signs require urgent veterinary review and locally appropriate authority guidance.

The database atomically reserves at most 10 calls/organization/day (UTC). Each response is capped at 1,200 output tokens and a 30-second timeout. Failed calls still consume quota. This caps requests, not currency; provider billing ceilings must also be configured. Change the SQL quota and redeploy its function to customize this limit. AI results are transient; copy reviewed findings to a health case to retain them. Structured durable assessments and review history remain pending.

Some providers offer model-specific free allowances (e.g. Gemini's OpenAI-compatible endpoint). Availability, geography, rate limits, data retention and billing eligibility vary by project. Check the provider console, select a supported text model and confirm JSON-mode compatibility. Do not assume a paid ChatGPT subscription supplies API access or that hosted inference will stay free.

Image assessment is **not implemented**. Private originals can be uploaded and reviewed by a veterinarian. The app does not invent image findings or encourage untrained necropsy. A future image adapter must perform quality checks, use only authorized batch photos and record consent/evidence/model/human review.


## Per-day rating column

The compact daily form supplies immediate **rule-based preview** as fields change. AI runs after a saved entry, never on each keystroke. `/api/daily-rating` retrieves only the authorized batch's saved logs and inventory; it does not accept arbitrary client evidence. Same-day entries are aggregated, and the previous three actual calendar days form the baseline. Missing days do not become zero. Categories: No flags, Monitor, Needs attention, Limited data. They are trend labels, not health/quality grades. Rule flags use mortality ≥0.5% of initial placement, intake drop >20%, mortality above twice baseline (and >2 birds), and water/feed deviation >25%. Thresholds are transparent screening examples, not validated strain targets. Partial-day periods are explicitly identified as a limitation.

The optional JSON model response cannot downgrade a rule-based Needs attention rating or override missing data with No flags. Failures use rules. AI is only called for saved days and counts toward the organization-wide ten-call daily cap, with 700 output tokens and 30-second timeout. Existing full health assessments retain their separate 1,200-token cap.

`daily_ratings` has per-batch read policies and no client write policies. Only an optional server-side service-role writer stores model responses after the request's JWT and batch authorization succeed. Without that configuration, generated AI results are device-cached. Corrected day/baseline evidence changes the cache key and withholds stale ratings. Local caches and drafts on shared devices should be cleared on signout/device handoff. Consent remains required; demo does not send any data to a provider.
