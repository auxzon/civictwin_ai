# CivicTwin AI — Locked Architecture Decisions

**Status: FROZEN.** This document is the single source of truth for every
binding architecture decision made for this project. It supersedes any
ambiguity in `CivicTwin_AI_Final_Engineering_Blueprint_V2.pdf` (EDD V2)
where the two conflict. Nothing in this file may be changed without
explicit approval from the Architect/PM. Implementation must never
silently deviate from what's recorded here — if a decision is unclear
or contradicted by new requirements, stop and ask.

---

## From EDD V2 (Engineering Blueprint, Documents 01–07)

1. **Explicit synchronous pipeline.** Flutter Web Client → API Gateway →
   Cache Interceptor → Context Hydration → Gemini LLM → Schema Enforcement
   → Deterministic Post-Processing → History Sync → GeoJSON Rendering.
   No multi-agent frameworks, no async job queues for the core mission flow.

2. **Map-first, edge-first rendering.** No tabular dashboards. The Google
   Map is the application canvas; all UI is floating glassmorphic overlays.

3. **Deterministic reasoning boundary.** Gemini performs semantic
   reasoning and relationship mapping only. It is strictly prohibited from
   performing budget math, risk indexing, or score calculations — those
   are native Python (`impact_engine.py`, `timeline_engine.py`).

4. **Cache-accelerated execution.** Every mission command is hashed
   (SHA-256 of `lowercase(command)_constituency_id`) and checked against
   the `ai_cache` Firestore collection before invoking Gemini. Cache
   entries expire on a 2-hour sliding TTL.

5. **Performance targets.** P95 core API response < 2.0s; cache hit
   latency < 300ms; Flutter Web initial hydration < 3.0s.

6. **Backend folder structure** (exact, per Document 01):
   ```
   backend/
   ├── main.py
   ├── config/settings.py
   ├── api/v1/router.py, api/v1/controllers/mission.py
   ├── core/security.py, core/logging.py, core/exceptions.py
   ├── domain/schemas/{requests,responses}.py, domain/models/firestore.py
   ├── services/{ai_pipeline,impact_engine,timeline_engine,report_service}.py
   └── infrastructure/{firestore_repo,gemini_client,pdf_generator}.py
   ```

7. **Firestore schema** (exact collections, fields, and validators as
   specified in Document 02): `system_config`, `users`, `constituencies`
   (+ `wards`, `signals` subcollections), `ai_cache`, `mission_history`.
   Composite indexes and security rules are specified verbatim in
   `firebase/firestore.indexes.json` and `firebase/firestore.rules`.

8. **API contract.** `POST /api/v1/mission/generate`, Bearer JWT auth,
   15 req/min rate limit, 45s hard timeout. Request/response JSON shapes
   are fixed per Document 03.

9. **AI schema enforcement.** Gemini must return exactly 3 `AIMissionBrief`
   objects per request, matching the rigid Pydantic schema in Document 04
   (mission_id, mission, priority, budget, confidence,
   confidence_explanation, beneficiaries, estimated_completion,
   department, evidence [max 3], risks, action_items [exactly 3],
   success_metrics [exactly 2], timeline_decay_rate, alternative).

10. **Impact score formula** (exact weights, Document 04 /
    `system_config.impact_weights`): Population 30%, Severity 25%,
    Budget Efficiency 20%, Infrastructure 15%, Signals 10%.

11. **Flutter state machine.** `OperationalState` enum:
    `idle → listening → thinking → animating → planLoaded`, managed via
    Riverpod `StateNotifier` exactly as specified in Document 05.

12. **Visual design tokens.** Grayscale map skin (`#111111` background,
    `#263238` arterial roads, `#000000` environmental suppression);
    glassmorphic panels (`ImageFilter.blur(sigmaX:10, sigmaY:10)`,
    `Colors.black.withOpacity(0.65)`, 1.5px `#00E5FF` @ 0.2 opacity border).

13. **96-hour delivery roadmap** (Document 06): Day 1 backend/seed setup,
    Day 2 AI orchestration/cache, Day 3 Flutter map UI, Day 4 voice +
    glassmorphic widgets + demo-safety fallback.

---

## Architect Override Memo (supersedes EDD V2 where noted)

### Decision 1 — Gemini SDK
Use the **Gemini Developer API** via the **`google-genai`** library
(`from google import genai`), authenticated with `GEMINI_API_KEY`.
**Do NOT use Vertex AI.** Rationale: simpler setup, faster iteration,
lower complexity for a 4-day build, uses a personal Google account.
*(Overrides EDD V2's ambiguous "Vertex AI / Gemini API wrapper" comment
in `services/ai_pipeline.py`.)*

Current pin: `google-genai==2.10.0`. This requires `pydantic>=2.12.5`
and `httpx>=0.28.1` — see `requirements.txt` for the full resolved,
verified dependency set.

### Decision 2 — Authentication
Use the **Firebase Admin SDK**: `firebase_admin.auth.verify_id_token()`.
**Do NOT use** `google.oauth2.id_token.verify_oauth2_token()` (the
literal code sample in EDD V2 Document 03 was inconsistent with the
stated "Firebase JWT validation" purpose — Firebase Admin SDK is the
official, corrected implementation).

### Decision 3 — PDF Generation
**Out of scope for MVP.** Do not implement `report_service.py` or
`pdf_generator.py` in this phase. The architecture (folder structure,
downstream flow diagram) must remain shaped so these can be added later
without refactoring — i.e., `services/` and `infrastructure/` keep the
placeholders reserved, but no code is written against them yet.

### Decision 4 — Flutter Folder Structure
Feature-first, exactly as follows (overrides/clarifies EDD V2 Document 05,
which only specified the `map_dashboard` provider path):
```
lib/
├── core/
│   ├── constants/
│   ├── network/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── authentication/
│   ├── map/
│   ├── mission/
│   ├── timeline/
│   ├── voice/
│   ├── history/
│   └── settings/
├── shared/
└── main.dart
```

### Decision 5 — Firestore Access
**Firestore is backend-only.** Flutter never talks to Firestore directly
— no `cloud_firestore` package in `pubspec.yaml` (Firebase Auth uses
`firebase_auth`/`firebase_core` only, which do not require it). All data
flows: `Flutter → FastAPI → Firestore → Gemini → FastAPI → Flutter`.
*(This clarifies/restricts the ADR's "native real-time websocket
listener streams" language in EDD V2 Document 07 — those streams, if
ever used, would be Firestore-Admin-SDK-side within the backend, never
client-side.)*

### Decision 6 — Realtime
**No WebSockets. No realtime listeners.** REST APIs only, for the entire
MVP.

### Decision 7 — Speech Input
Primary: Browser Web Speech API. Fallback: **hidden Demo Mode** — when
enabled, the microphone button submits the fixed string
`"Allocate ₹50 lakh for drinking water in Ward 14"` instead of recording
audio, to guarantee reliable live-demo behavior.

### Decision 8 — Maps
Google Maps business data (wards, signals, polygons) is served through
backend APIs only. Flutter never loads map business data directly from
Firestore.

### Decision 9 — Mission History
Every generated Mission Brief is stored in `mission_history` with fields:
`mission_id`, `timestamp`, `command`, `response`, `impact_score`,
`constituency_id`.

### Decision 10 — Development Process
No redesign. No feature additions. No technology changes. No folder
structure changes. Any future conflict must be raised and approved
before implementation proceeds — never resolved by silent assumption.

---

## Phase 1 Audit Fixes (applied, see `CHANGELOG.md` for detail)

- **F1 (Critical):** Removed the `allow_origins=... or ["*"]` CORS
  fallback. `CORS_ALLOWED_ORIGINS` is now a required, validated setting;
  the app fails fast at startup if it is empty or contains `"*"`.
- **F2 (High):** `google-genai` re-pinned from a stale `0.4.0` to the
  current stable `2.10.0`, with `pydantic`/`pydantic-settings`/`httpx`
  co-verified for dependency-resolution compatibility.
- **F5 (Medium):** `typing_extensions` added as an explicit, pinned
  dependency (previously relied on transitively via `pydantic`).
- **F8/F9 (Medium):** Added `pyproject.toml` with Ruff lint/format
  config, plus a minimal `pytest` configuration and a `/health` smoke
  test suite (`tests/conftest.py`, `tests/test_health.py`).

Findings F3, F4, and F7 (Firestore rule scoping gaps inherited verbatim
from EDD V2 Document 02) remain **open by design** — they require
Architect/PM sign-off to amend a frozen document and are not addressed
in this repository scaffold.

## Phase 2 Implementation Notes

- **Firestore client construction bug (found and fixed during Phase 2
  self-review):** `infrastructure/firestore_repo.py` initially constructed
  `google.cloud.firestore.Client()` directly, which resolves credentials
  via `google.auth.default()` (Application Default Credentials) — a
  mechanism that reads `GOOGLE_APPLICATION_CREDENTIALS` from the real OS
  environment. Since pydantic-settings loads `.env` values into the
  `Settings` model without exporting them to `os.environ`, a
  locally-configured `.env` value would silently fail ADC resolution.
  Fixed by using `firebase_admin.firestore.client()` instead, which
  reuses the credentials already loaded explicitly via
  `firebase_admin.credentials.Certificate(...)` in `main.py`. Verified
  live: the original code raised `DefaultCredentialsError`; the fix
  boots and serves requests correctly.
- **Ward resolution for impact scoring:** `AIMissionBrief` (Document 04)
  has no direct `ward_id` field — only `evidence` (signal IDs) and an
  `alternative` runner-up ward ID. `services/ai_pipeline.py` resolves the
  primary target ward as the majority `ward_id` among a brief's cited
  evidence signals, falling back to `alternative` if no evidence
  resolves, and to conservative defaults (population=1, infra=1) if
  neither resolves — this is a necessary implementation decision filling
  a gap in the frozen schema, not a deviation from it.
- **Rate limiting (15 req/min, Document 03):** implemented as a small
  in-memory fixed-window limiter inside `api/v1/controllers/mission.py`
  rather than as a new top-level module or third-party dependency, to
  avoid both a folder-structure change and introducing new technology.
  Documented limitation: per-process only, resets on restart, and does
  not coordinate across multiple Cloud Run instances.

## Phase 3 Implementation Notes

- **Additive History endpoint:** `GET /api/v1/mission/history` was added
  to the backend during Phase 3 to support Document 01's "History Mode"
  state, which has no corresponding read endpoint in the literal Document
  03 API contract. This is an addition, not a change to any existing
  frozen behavior — `POST /mission/generate` is untouched.
- **Flutter verification gap:** no Flutter/Dart SDK was available in the
  environment Phase 3 was built in, and `pub.dev` was not reachable to
  install one. All Dart code was checked with a custom static script
  (import-path resolution, brace balance) and written against
  well-established stable APIs, but has not been run through `flutter
  analyze` or compiled. See `PROJECT_SETUP.md` for what to verify first.
- **`firebase_options.dart` is an intentional stub** that throws instead
  of containing fabricated API keys — must be regenerated via
  `flutterfire configure` against a real Firebase project before running
  the app.
- **Glassmorphic/visual design (Document 05's "Aero Glass" specs) was
  deliberately not implemented** in Phase 3 — functional state wiring
  (Riverpod providers, API calls, the exact state machine) was
  prioritized over visual polish, per explicit instruction.
- **Timeline decay-rate reconciliation:** the frozen state notifier
  (`updateTimeline`) takes one decay rate for the whole timeline, but a
  `MissionResponse` can contain 3 briefs with different rates. The
  primary (first) brief's rate is used as the shared value — a necessary
  implementation decision, not specified in the frozen docs.
