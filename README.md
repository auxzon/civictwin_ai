# CivicTwin AI

**The AI Brain for Constituency Planning**

A spatial decision intelligence platform helping Members of Parliament
prioritize MPLADS fund allocation using voice-driven, map-first plan
generation. See `DECISIONS.md` for the full frozen architecture and
`PROJECT_SETUP.md` for detailed setup instructions.

**Status:** Phase 3 — Flutter client implemented (state management, auth,
map wiring, mission pipeline integration, voice input with demo-mode
fallback, timeline, history). Visual/glassmorphic design polish is
deliberately not implemented — see `CHANGELOG.md`.

---

## Quick Start

```bash
# 1. Backend environment
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# → edit .env: GEMINI_API_KEY, FIREBASE_PROJECT_ID,
#   GOOGLE_APPLICATION_CREDENTIALS, CORS_ALLOWED_ORIGINS

# 2. Firebase (one-time, requires a real Firebase project — see PROJECT_SETUP.md)
firebase login
firebase deploy --only firestore:rules,firestore:indexes

# 3. Seed mock data
python -m scripts.seed_database

# 4. Run
uvicorn main:app --reload
# → http://localhost:8000/health

# 5. Verify
pytest
ruff check .
ruff format --check .
```

Full step-by-step instructions, including Firebase project creation and
troubleshooting, are in **[`PROJECT_SETUP.md`](./PROJECT_SETUP.md)**.

## Repository Layout

```
civictwin-ai/
├── backend/                        # FastAPI service
│   ├── main.py                     # Entrypoint (health check, CORS, logging, Firebase init, router mount)
│   ├── config/settings.py          # Pydantic-settings configuration
│   ├── core/
│   │   ├── logging.py              # Structured JSON logging
│   │   ├── security.py             # Firebase Admin SDK JWT verification
│   │   └── exceptions.py           # Unified exception handlers
│   ├── api/v1/
│   │   ├── router.py                # Aggregated v1 router
│   │   └── controllers/mission.py  # Mission generation endpoint (auth, rate limit, cache, pipeline)
│   ├── domain/
│   │   ├── schemas/{requests,responses}.py  # API request/response DTOs
│   │   └── models/firestore.py     # Typed Firestore document mirrors
│   ├── services/
│   │   ├── ai_pipeline.py          # Gemini orchestration + deterministic score injection
│   │   ├── impact_engine.py        # Pure deterministic scoring formula
│   │   └── timeline_engine.py      # Decay-rate clamping, Flutter-parity opacity formula
│   ├── infrastructure/
│   │   ├── firestore_repo.py       # Sole Firestore access point
│   │   └── gemini_client.py        # google-genai SDK wrapper
│   ├── prompts/recommended_plan.txt # Gemini prompt template
│   ├── scripts/
│   │   ├── mock_data.py            # Mock dataset definitions
│   │   └── seed_database.py        # Idempotent Firestore seeder
│   ├── tests/                      # 36 tests — pure functions, schemas, mocked controller integration
│   ├── pyproject.toml              # Ruff lint/format + pytest config
│   ├── requirements.txt            # Pinned, dependency-resolution-verified
│   └── .env.example
├── frontend/                       # Flutter Web client
│   ├── pubspec.yaml                # Approved dependency set (Decisions 4-7)
│   ├── analysis_options.yaml       # Dart lint config (flutter_lints)
│   ├── assets/map_style.json       # Grayscale map skin (Document 05)
│   └── lib/
│       ├── main.dart, app.dart     # Bootstrap + auth-gated routing
│       ├── firebase_options.dart   # Stub — regenerate via `flutterfire configure`
│       ├── core/
│       │   ├── theme/              # Design tokens from Document 05
│       │   ├── network/            # API client + typed exceptions
│       │   └── constants/          # Build-time config (API base URL)
│       └── features/
│           ├── authentication/     # AuthService, SignInScreen
│           ├── map/                # State machine (verbatim, Document 05) + MapScreen
│           ├── mission/            # DTOs, repository, controller
│           ├── timeline/           # Timeline slider
│           ├── voice/              # Web Speech API + Demo Mode (Decision 7)
│           └── history/            # History repository/provider (additive endpoint)
├── firebase/
│   ├── firestore.rules             # Verbatim from EDD V2 Document 02
│   └── firestore.indexes.json
├── .github/workflows/backend-ci.yml
├── firebase.json
├── .firebaserc
├── DECISIONS.md                    # Every locked architecture decision — read this first
├── PROJECT_SETUP.md                # Full setup + troubleshooting guide
├── CHANGELOG.md
├── LICENSE
└── .editorconfig
```

## Key Documents

- **[`DECISIONS.md`](./DECISIONS.md)** — the single source of truth for
  every frozen architecture decision (Gemini SDK choice, auth mechanism,
  folder structure, Firestore access rules, etc.). Read this before
  making any implementation choice.
- **[`PROJECT_SETUP.md`](./PROJECT_SETUP.md)** — complete setup,
  verification, and troubleshooting instructions.
- **[`CHANGELOG.md`](./CHANGELOG.md)** — what's been built and what
  audit findings were fixed in this phase.

## What's Implemented vs. Deferred

| Area | Status |
|---|---|
| Repo structure, config, environment | Done — Phase 1 |
| Firebase/Firestore setup, security rules, indexes | Done — Phase 1 |
| Mock dataset + seeding script | Done — Phase 1 |
| Lint (Ruff), test scaffold, CI | Done — Phase 1 |
| Mission Generator, Gemini pipeline, Impact/Timeline Engines | Done — Phase 2 |
| API controller (auth, rate limiting, caching, error handling) | Done — Phase 2 |
| Mission history read endpoint (additive gap-fill) | Done — Phase 2/3 |
| Flutter state management, auth, networking, map wiring | Done — Phase 3 |
| Voice input (Web Speech API + Demo Mode fallback) | Done — Phase 3 (unverified, no toolchain — see below) |
| Glassmorphic visual design, camera animations, neon overlays | Not implemented — deferred by request |
| PDF report generation | Deferred — Decision 3, future scope |

### Important: Flutter code has not been compiled or analyzed

No Flutter/Dart SDK and no `pub.dev` access were available in the
environment this was built in. Every Dart file was written against
well-established, stable APIs and checked with a custom static script
(import-path resolution, brace balance — see `CHANGELOG.md` for what that
caught), but **none of it has been run through `flutter analyze` or an
actual compiler.** Backend code, by contrast, was fully compiled, unit
tested (39 tests), linted, and live-booted — see `PROJECT_SETUP.md`'s
"Known verification gap" section before debugging the Flutter side
blindly; `lib/features/voice/web_speech_bindings.dart` is the highest-risk
file (raw browser JS interop) and should be the first thing manually
smoke-tested in a real browser.

### Try it (once `.env` and Firebase are configured)

```bash
curl -X POST http://localhost:8000/api/v1/mission/generate \
  -H "Authorization: Bearer <firebase-id-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "constituency_id": "const_mumbai_north",
    "command": "Allocate funds for drinking water in Ward 14",
    "map_bounds": {
      "ne": {"lat": 19.1900, "lng": 72.8700},
      "sw": {"lat": 19.1700, "lng": 72.8400}
    }
  }'
```

Interactive API docs (auto-generated by FastAPI) are available at
`http://localhost:8000/docs` once the server is running.
