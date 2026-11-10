# Daily performance and photo triage

## Daily entry

Use actual consumed feed (kg), water (L), separate deaths/culls, optional measured weight and notes. Select **Full day** only for one full 24-hour entry, or **Partial day** with its actual hours for incremental, non-overlapping entries. Multiple entries add together. Two full-day entries on the same date represent 48 reported hours and must be corrected, not silently treated as a valid day. Older entries without duration remain unconfirmed until edited. Unknown is not zero.

## Single-day results

Performance and data completeness are separate. The app can flag mortality or severe respiratory signs from a single record, including a partial day and missing other readings. Mortality uses opening inventory where prior complete loss counts and movements allow it; otherwise the initial placement reference is explicitly labeled. A 0.5% mortality screening threshold is an example action rule, not a disease diagnosis.

For intake, the app uses approved source-backed age bands configured under **Settings → Approved daily targets**. Enter the actual company/veterinarian standard and its version/context for this breed, housing, climate and season. No breeder norms are invented. Feed and water are normalized per opening live bird for a full 24-hour period. Same-day pickups/transfers without timing prevent reliable per-bird comparisons. Weight is measured only, with sample-size weighting when sizes are available.

If no target applies, the preceding three complete days can provide an own-flock per-bird baseline. Intake beyond ±20%, or water/feed ratio beyond ±25%, produces a screening concern. These are explainable example thresholds, not calibrated diagnostic cutoffs. Incomplete periods are not projected. Without appropriate targets/history/inventory the app explains the limitation rather than labeling intake high/low. High intake is not automatically good performance.

The dashboard shows recent flagged days as **Early warnings**, including date, facts, reference and recommended checks. It is not a background notification service. No alert implies no assurance of health. Corrected readings, periods, inventory and targets invalidate cached assessments.

## AI connection

Vercel deployment requests use project OIDC to authenticate to AI Gateway; no provider key is exposed or needed in browsers. `AI_GATEWAY_MODEL` selects the verified model from the current catalog. The configured model is `google/gemini-3.5-flash-lite`, supporting text, images and structured output with catalog `no_training=all`. Account credit/payment eligibility still applies. A real connectivity test is required before reporting AI as connected; failures leave rules available and display the provider's actionable setup status.

Owner consent under **Settings → Enable AI data sharing** is required before sending any batch records or photographs. Daily assessments send authorized calculated facts and bounded recent notes. Photo reviews also send an explicitly requested resized private image; no photos are sent by text-only assessments. Review the Gateway and model provider's current data-handling terms.

Limits: 10 combined AI calls per organization/UTC day AND a project-wide maximum of 10 calls/day through an atomic database quota. Failed provider calls count too. Requests cap output at 900 tokens, text evidence at 16,000 UTF-8 bytes, 30 seconds, and a conservative estimated one-cent maximum using configured per-token ceilings. Thus the application's reserved-call ceiling is $0.10/project/day at the verified pricing. This is an application estimate; configure a provider-side budget in Gateway for independent billing enforcement. No credits or paid plan are purchased automatically. Price changes require reviewing the bound. Other model slugs are rejected until their pricing is checked; direct-provider users must set price ceilings explicitly.

AI responses are schema-validated, remain unreviewed, and cannot lower urgent deterministic alerts or authorize medication/record changes. Records, notes and images are untrusted evidence, never instructions. Shared daily-result cache requires the optional server-only cache writer key; otherwise results are device-cached with model, timestamp, human-review state and source references. Do not claim shared persistence when that key is absent.

## Photo review

After **Photo checkpoints → Upload image**, open **Review flock / dead-chick photo with AI**. Add timing/symptoms and select **Assess image with AI**. Original images stay private with existing expiring viewer URLs. The server authorizes both the batch and private object, decodes the file with a 20-million-pixel limit, strips metadata, and resizes to at most 512×512 before provider transmission. Oversized/invalid files are refused. The image token allowance is conservatively budgeted separately from text.

The result includes image quality, visible findings, possible infectious/noninfectious causes, missing information, safe husbandry checks, urgency and suggested veterinary examination/tests. It cannot confirm a disease in a dead chick from a photograph. Do not have untrained staff perform necropsies. Image results are saved as audited health cases when the caller can submit cases. A source image hash and record/clinical fingerprints are stored; corrected inputs mark saved context stale.

## Verification limits

Unit tests and server-rendered controls cover calculations, authorization scope, malformed/provider failures, target edits, missing periods and urgent-alert protection. A live synthetic model probe checks provider access without farm or user data. The temporary probe requires a secret and expires automatically; it is not a public generation endpoint. Real-user clinical validation, provider-dashboard billing review and browser upload-to-assessment testing remain separate checks. See the release report for actual connection success or external setup blockers.
