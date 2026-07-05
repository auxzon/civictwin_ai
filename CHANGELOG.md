# Changelog

All notable changes to this project are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased] — Phase 3: Flutter Client

### Added
- `lib/main.dart`, `lib/app.dart`: real app bootstrap — Firebase init,
  Riverpod `ProviderScope`, auth-gated routing (`SignInScreen` vs
  `MapScreen`).
- `lib/firebase_options.dart`: intentional stub that throws a clear error
  instead of shipping fabricated API keys — must be regenerated via
  `flutterfire configure` (documented in `PROJECT_SETUP.md`).
- `core/theme/`: design tokens taken directly from Document 05's Visual
  Specifications (`#111111`/`#263238`/`#000000`/`#00E5FF`) — no invented
  colors.
- `core/network/api_client.dart`: REST client with injected token
  provider (decoupled from `firebase_auth` for testability), decodes the
  backend's unified `{"error": {"code","message"}}` shape into a typed
  `ApiException`.
- `features/authentication/`: `AuthService` (thin `firebase_auth`
  wrapper), `SignInScreen` (plain, functional — no visual design work).
- `features/map/providers/map_state_notifier.dart`: implemented verbatim
  from Document 05 (the state machine, not a paraphrase).
- `features/map/map_screen.dart`: functional `GoogleMap` wiring — mic
  button, mission brief cards, timeline slider, history drawer. Plain
  `Card`/`ListTile` presentation; glassmorphic visual polish deliberately
  not implemented per explicit instruction to avoid unrequested design work.
- `features/mission/`: Dart DTOs mirroring the backend schemas exactly,
  `MissionRepository`, and `MissionController` driving the
  Idle→Thinking→Animating→MissionLoaded transitions.
- `features/voice/`: `VoiceInputService` implementing Decision 7 exactly
  (Web Speech API primary, fixed Demo Mode fallback string, silent
  fallback on any unsupported-browser or recognition error).
- `features/timeline/timeline_slider.dart`: functional slider wired to
  `updateTimeline`; documents the ward/brief-decay-rate reconciliation
  decision (uses the primary brief's rate) since Document 05 doesn't
  specify how to handle multiple briefs with different rates.
- `features/history/`: repository + provider for the additive
  `GET /mission/history` endpoint (see below).
- `analysis_options.yaml`: Dart lint configuration (`flutter_lints`) —
  the Dart-side equivalent of the backend's Ruff config, previously
  missing.
- `assets/map_style.json`: the grayscale map skin as an actual Google
  Maps style JSON array, not just described in prose.

### Added (Backend — additive gap-fill for Flutter's History Mode)
- `GET /api/v1/mission/history`: not part of the literal EDD V2 Document
  03 contract, which only specifies `POST /mission/generate`. Added
  because Document 01's state machine requires a "History Mode (Fetches
  historical plan collections from session)" transition with no
  corresponding read endpoint ever specified. Uses the composite index
  already defined in `firestore.indexes.json`
  (`constituency_id` ASC, `created_at` DESC) from Phase 1 — no index
  changes needed. 3 new tests added (39 total, all passing).

### Fixed
- Caught via a custom static Dart cross-file import checker (no Flutter
  SDK available to run `flutter analyze`): a wrong relative-import depth
  in `features/history/models/mission_history_item.dart` (`../mission/...`
  instead of `../../mission/...`). Fixed and re-verified.

### Known Verification Gap — read before assuming Dart code is bug-free
**No Flutter/Dart SDK or `pub.dev` access was available** in the
environment this was written in. Every backend change in this phase was
verified the same way as Phase 2 (compiled, tested, linted, live-booted).
The Dart/Flutter code was written carefully against known-stable APIs and
checked with a custom script for import-path correctness and brace
balance, but **has not been run through `flutter analyze` or compiled.**
See `PROJECT_SETUP.md`'s "Known verification gap" section for exactly
what to check first (`web_speech_bindings.dart` is the highest-risk file).

### Explicitly Not Implemented
- Glassmorphic visual polish, camera animations, neon ward-boundary
  painting (Document 05's "Aero Glass" specs) — deliberately deferred;
  current scope prioritized correct functional wiring over visual design
  work, per explicit instruction.
- Constituency picker (hardcoded to `const_mumbai_north`).
- PDF report generation (Decision 3 — still deferred).

## [Unreleased] — Phase 2: Backend Business Logic

### Added
- `domain/models/firestore.py`: typed Pydantic mirrors of every Firestore
  document (SystemConfig, User, Constituency, Ward, Signal, AICacheEntry,
  MissionHistoryEntry).
- `domain/schemas/requests.py`, `domain/schemas/responses.py`: validated
  API request/response DTOs matching Document 03's contract exactly,
  including bounding-box sanity validation (`sw` must be south-west of
  `ne`) and brief-shape constraints (exactly 3 action items, exactly 2
  success metrics, max 3 evidence IDs, decay rate in [0.01, 0.50]).
- `core/security.py`: Firebase Admin SDK JWT verification (Decision 2),
  replacing the inconsistent `google.oauth2.id_token` sample from EDD V2
  Document 03. Verified live against real `firebase_admin.auth.verify_id_token`
  behavior for missing-header (422) and invalid-token (401) cases.
- `core/exceptions.py`: unified exception handlers with custom exception
  types (`ConstituencyNotFoundError`, `BudgetExhaustedError`,
  `MissionPipelineError`), producing a consistent `{"error": {"code",
  "message"}}` JSON shape for every error path.
- `infrastructure/firestore_repo.py`: the sole Firestore access point —
  cache check/write, constituency/ward/signal reads, in-memory bounding-box
  filtering for signals, mission history writes.
- `infrastructure/gemini_client.py`: thin `google-genai` wrapper using
  `client.aio.models.generate_content` with `types.GenerateContentConfig`
  (schema-constrained JSON output). API surface verified directly against
  the installed `google-genai==2.10.0` package before writing this module.
- `services/impact_engine.py`: pure deterministic scoring function, exact
  formula and weights from Document 04. Zero I/O, zero LLM calls.
- `services/timeline_engine.py`: decay-rate clamping and a Flutter-parity
  opacity formula (mirrors `AppUIStateNotifier.updateTimeline` exactly),
  for testability and cross-stack consistency.
- `services/ai_pipeline.py`: orchestrates Gemini inference and deterministic
  post-processing. Resolves each brief's target ward from its cited
  evidence signals (a necessary implementation decision — see
  `DECISIONS.md`), then unconditionally overwrites `impact_score` with the
  `impact_engine` result before any brief can reach the response DTO.
- `backend/prompts/recommended_plan.txt`: the prompt template referenced
  by path in Document 04.
- `api/v1/controllers/mission.py`: the full request lifecycle — auth,
  in-memory rate limiting (15/min), cache check, context hydration,
  Gemini inference with a 45s hard timeout, deterministic scoring,
  budget capping, response building, and concurrent persistence
  (mission_history + ai_cache writes).
- `api/v1/router.py`: v1 router aggregation, mounted in `main.py`.
- 26 new tests across `test_impact_engine.py`, `test_timeline_engine.py`,
  `test_schemas.py`, `test_ai_pipeline.py`, and `test_mission_controller.py`
  (36 total, all passing). Controller tests use FastAPI dependency
  overrides with in-memory fakes for Firestore/Gemini — no real network
  calls in the test suite.

### Fixed
- **Firestore ADC credential bug** (found via live boot-testing during
  Phase 2, not caught by unit tests alone): `firestore_repo.py` originally
  constructed `google.cloud.firestore.Client()` directly, which failed
  with `DefaultCredentialsError` because Application Default Credentials
  resolution reads `GOOGLE_APPLICATION_CREDENTIALS` from the real OS
  environment, not from pydantic-settings' parsed `.env` values. Fixed by
  using `firebase_admin.firestore.client()`, which reuses the credentials
  already loaded explicitly in `main.py`. See `DECISIONS.md` for the full
  writeup.
- Added a scoped Ruff `per-file-ignore` for `B008` in
  `api/**/controllers/*` — FastAPI's `Depends()`-as-default-argument
  pattern is idiomatic, not a bug, and was being flagged incorrectly.

### Explicitly Not Implemented (unchanged from Phase 1 scope)
- `report_service.py`, `pdf_generator.py` (Decision 3 — deferred).
- Flutter screens, voice input, Google Maps integration (Phase 3).
- `core/security.py`'s role/constituency-based authorization beyond
  identity verification (the frozen schema defines `users.role` and
  `users.constituency_id`, but Document 03's endpoint contract does not
  specify authorization rules beyond "valid Bearer token" — flagged as an
  open question rather than assumed).

## [0.1.0] — Phase 1: Initial Project Repository

### Added
- Backend scaffold: `main.py` (FastAPI entrypoint, CORS, structured
  logging, Firebase Admin init, `/health` endpoint), `config/settings.py`
  (pydantic-settings configuration), `core/logging.py` (structured JSON
  logging).
- Repository structure for Phase 2/3 modules (`api/`, `domain/`,
  `services/`, `infrastructure/` — empty package skeletons, no business
  logic yet, per phased delivery plan).
- Mock dataset (`scripts/mock_data.py`) and idempotent Firestore seeder
  (`scripts/seed_database.py`): 1 constituency, 5 wards, 11 signals.
- Firebase configuration: `firebase.json`, `.firebaserc`,
  `firebase/firestore.rules`, `firebase/firestore.indexes.json` (verbatim
  from EDD V2 Document 02).
- Flutter dependency manifest (`frontend/pubspec.yaml`) and feature-first
  folder skeleton per Decision 4.
- Test suite: `tests/conftest.py` (isolated env fixtures, synthetic
  credential), `tests/test_health.py` (health endpoint smoke tests).
- Lint/format configuration: `pyproject.toml` with Ruff.
- Documentation: `README.md`, `PROJECT_SETUP.md`, `DECISIONS.md`,
  `.gitignore`, `.editorconfig`, `LICENSE`.
- CI workflow: `.github/workflows/backend-ci.yml` (lint, format check,
  tests on push/PR).

### Fixed (Phase 1 Audit Remediation)
- **[Critical] F1:** Removed `allow_origins=settings.cors_allowed_origins
  or ["*"]` wildcard CORS fallback in `main.py`. Added a `field_validator`
  in `config/settings.py` that raises `ValueError` at startup if
  `CORS_ALLOWED_ORIGINS` is empty or contains `"*"`. Verified via live
  test: both the missing-origin and wildcard-origin cases now fail fast
  instead of silently permitting cross-origin credentialed requests.
- **[High] F2:** Re-pinned `google-genai` from a stale `0.4.0` to the
  current stable `2.10.0`. This required co-bumping `pydantic` to
  `2.13.4` and `pydantic-settings` to `2.14.2` (google-genai requires
  `pydantic>=2.12.5`), and pinning `httpx==0.28.1` exactly (satisfies
  google-genai's `httpx>=0.28.1` requirement while remaining compatible
  with Starlette's `TestClient`). Full dependency resolution and a live
  cross-import test were run to confirm no conflicts.
- **[Medium] F5:** Added `typing_extensions==4.16.0` as an explicit,
  version-pinned dependency in `requirements.txt` (previously relied on
  transitively via `pydantic` with no explicit declaration).
- **[Medium] F6:** Documented the "must run from `backend/`" requirement
  explicitly in `PROJECT_SETUP.md` and its troubleshooting table.
- **[Medium] F8:** Added `pyproject.toml` with a Ruff configuration
  (lint + format). Full codebase passes `ruff check` and
  `ruff format --check` with zero issues.
- **[Medium] F9:** Added `pytest` configuration
  (`[tool.pytest.ini_options]` in `pyproject.toml`) and a `/health`
  smoke test suite. Tests run against a fully isolated fixture
  environment (synthetic Firebase credential, no real secrets).

### Deferred (open items, tracked in `DECISIONS.md`)
- F3, F4, F7: Firestore security rule scoping gaps inherited verbatim
  from EDD V2 Document 02 (`signals` write rule not scoped to
  constituency, `mission_history` write rule not checking existing
  document ownership, `ai_cache` fully open to any authenticated user).
  These require Architect/PM approval to amend a frozen document and are
  intentionally left unchanged in this scaffold.
- F10: Confirmed `backend/`/`frontend/` root naming per explicit
  instruction (Decision 4 supersedes the earlier open question).

### Explicitly Not Implemented (by design, per Phase 1 scope)
- Mission Generator, Gemini reasoning pipeline, Impact Engine, Timeline
  Engine, API controllers/business logic (Phase 2).
- Flutter screens, voice input, Google Maps integration (Phase 3).
- PDF report generation (Decision 3 — deferred to a future phase beyond
  the current roadmap).
