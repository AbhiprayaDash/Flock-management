# Daily performance and photo triage

## Daily entry

Use actual consumed feed (kg), water (L), separate deaths/culls, optional measured weight and notes. Select **Full day** only for one full 24-hour entry, or **Partial day** with its actual hours for incremental, non-overlapping entries. Multiple entries add together. Two full-day entries on the same date represent 48 reported hours and must be corrected, not silently treated as a valid day. Older entries without duration remain unconfirmed until edited. Unknown is not zero.

## Single-day results

Performance and data completeness are separate. The app can flag mortality or severe respiratory signs from a single record, including a partial day and missing other readings. Mortality uses opening inventory where prior complete loss counts and movements allow it; otherwise the initial placement reference is explicitly labeled. A 0.5% mortality screening threshold is an example action rule, not a disease diagnosis.

No Settings setup is required for intake screening. Approved source-backed company age bands, if already configured, take priority. Enter the actual company/veterinarian standard and its version/context for this breed, housing, climate and season. No breeder norms are invented. Feed and water are normalized per opening live bird for a full 24-hour period. Same-day pickups/transfers without timing prevent reliable per-bird comparisons. Weight is measured only, with sample-size weighting when sizes are available.

If no target applies, the preceding three complete days can provide an own-flock per-bird baseline. Intake beyond ±20%, or water/feed ratio beyond ±25%, produces a screening concern. These are explainable example thresholds, not calibrated diagnostic cutoffs. Incomplete periods are not projected. When approved targets and comparable history are absent, the automatic reference described below supplies an age-based comparison. Missing reporting periods or reliable inventory still prevent per-bird comparisons. High intake is not automatically good performance.

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

Unit tests and server-rendered controls cover calculations, authorization scope, malformed/provider failures, target edits, missing periods and urgent-alert protection. A live synthetic model probe checks provider access without farm or user data. The temporary secret-protected probe was removed after verification. Real-user clinical validation, provider-dashboard billing review and browser upload-to-assessment testing remain separate checks. See the release report for actual connection success or external setup blockers.

Starting mid-batch: the optional **Verified birds at start of day** count can anchor a single day's assessment when earlier daily loss records are unavailable. It must be a verified count, not a guess, and does not silently replace inventory movement records. Subsequent complete daily records carry that anchor forward. Conflicting opening counts prevent a reliable comparison.

## Live verification — 10 November 2026

Production synthetic generation reached AI Gateway, which rejected it with `customer_verification_required`: account verification/payment-method setup is required before free credits can be used. AI is therefore configured but **not operational**. In the Vercel team dashboard, open AI Gateway and complete its requested account verification, then retry an assessment after explicitly enabling organization AI sharing. No payment method, paid plan, credit top-up or data-sharing consent was added automatically. Daily rule-based alerts continue to work. The photo workflow requires a successful vision-model request; it has not been clinically validated.

Release verification: production build passed; 58 tests passed, one opt-in isolation test skipped. No browser upload-to-assessment check was performed.

## Automatic Indian university reference — no setup required

For flock days 1–42, when neither an approved company target nor three comparable complete days are available, the app automatically uses [Kerala Agricultural University](https://www.celkau.in/Animalhusbandry/chicken/feed.php) / [TNAU broiler guidance](https://agritech.tnau.ac.in/animal_husbandry/ani_chik_broilers.html): daily feed = age × 10 ÷ 4.4 g/bird; daily water = age × 5 mL/bird. The app deliberately limits this general reference to the first six weeks rather than extrapolating indefinitely.

These are approximate average-condition estimates, not modern strain-specific objectives. The source mentions seasonal variation of 5–10%; this is not an alert threshold. The application's ±20% screening margin is a separate product rule, not a published clinical or normal range. Temperature, breed and housing can change expected consumption, so persistent flags require contextual review. No feed/water restriction is recommended from these estimates. Comparisons require confirmed 24-hour totals, a reliable opening bird count and no same-day movements with unknown timing.

Existing records recalculate automatically; evidence version 3 invalidates old AI results. A missing weight reference no longer blocks intake assessment or appears as a required missing input; measured weights remain available without a growth grade. Optional Settings fields are overrides only. These checks run without AI and without provider setup.

## Dashboard possible health risks

Each flagged day now includes a source-linked **Possible health risks** section. Deterministic intake/mortality flags drive the content without requiring an AI call. Early chick mortality highlights brooding/transport, dehydration, failure to start and possible navel/yolk-sac infection as differentials for veterinary investigation; it does not diagnose these conditions. Low intake highlights hydration/growth concerns, high water directs checks of meters/leaks/heat/litter, and high feed directs wastage/measurement checks. Enteric disease concerns are conditional on environmental/clinical findings, not inferred from high water alone. Never restrict water to match reference estimates. Partial-day intake and unrelated batches cannot trigger these risk explanations. Tests include the reported day-one mortality/intake scenario and dashboard rendering.

Direct Gemini text and synthetic-image connectivity succeeded after server-only Vercel credentials were supplied. The earlier Gateway verification failure is bypassed by the direct provider configuration. Organization consent, provider quotas and veterinary review still apply.
