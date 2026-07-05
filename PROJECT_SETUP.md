# CivicTwin AI — Project Setup Guide

Complete setup instructions for the Phase 1 repository scaffold. Follow
these in order; each step is verifiable before moving to the next.

## Prerequisites

- Python 3.11+ (tested on 3.12)
- Node.js is **not** required for Phase 1 (no Flutter build yet)
- A Google Cloud / Firebase account
- `firebase-tools` CLI: `npm install -g firebase-tools`

## 1. Clone and enter the repository

```bash
cd civictwin-ai
```

## 2. Backend environment

**Important:** all backend commands below must be run from inside the
`backend/` directory. `main.py` and `scripts/seed_database.py` resolve
`.env` and internal imports (`config.settings`, `core.logging`, etc.)
relative to that working directory — running them from the repo root
will fail with a `.env` file not found or `ModuleNotFoundError`.

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
```

Edit `.env` and fill in:
- `GEMINI_API_KEY` — from [Google AI Studio](https://aistudio.google.com/apikey)
- `FIREBASE_PROJECT_ID` — your Firebase project ID (step 3 below)
- `GOOGLE_APPLICATION_CREDENTIALS` — path to your service account JSON (step 3)
- `CORS_ALLOWED_ORIGINS` — comma-separated list of allowed origins, e.g.
  `http://localhost:5000,https://your-flutter-web-domain.com`.
  **This must not be empty and must not contain `*`** — the app fails
  fast at startup otherwise (see `DECISIONS.md`, audit fix F1).

## 3. Firebase project setup

1. Go to the [Firebase Console](https://console.firebase.google.com) and
   create a new project (or use an existing GCP project).
2. Enable **Cloud Firestore** in Native mode: *Build → Firestore Database
   → Create database*.
3. Enable **Firebase Authentication**: *Build → Authentication → Get
   started*. Enable the sign-in method your MP-facing app will use.
4. Generate a service account key: *Project Settings (gear icon) →
   Service Accounts → Generate new private key*. Save the downloaded
   file as `firebase/service-account.json` in this repo (already covered
   by `.gitignore` — it will never be committed).
5. Update `.firebaserc` at the repo root with your real project ID:
   ```json
   { "projects": { "default": "your-actual-project-id" } }
   ```
6. Log in and deploy Firestore rules/indexes:
   ```bash
   firebase login
   firebase deploy --only firestore:rules,firestore:indexes
   ```

## 4. Seed the mock dataset

From inside `backend/` with the venv active:

```bash
python -m scripts.seed_database
```

This populates:
- `system_config/sys_01`
- `constituencies/const_mumbai_north`
- 5 documents in `constituencies/const_mumbai_north/wards`
- 11 documents in `constituencies/const_mumbai_north/signals`

Verify in the Firebase Console (Firestore Database tab) that these
documents appear as expected. The script is idempotent — re-running it
overwrites the same documents rather than duplicating them.

## 5. Run the backend

```bash
uvicorn main:app --reload
```

Verify at `http://localhost:8000/health` — expect:
```json
{"status": "ok", "service": "CivicTwin AI Backend", "environment": "development"}
```

## 6. Run tests

```bash
pytest
```

Expect `2 passed`. Tests run in a fully isolated environment (see
`tests/conftest.py`) — they never touch your real `.env`, real Firebase
project, or real Gemini API key.

## 7. Run lint and format checks

```bash
ruff check .
ruff format --check .
```

Both should report no issues. To auto-fix and auto-format:

```bash
ruff check --fix .
ruff format .
```

## 8. Frontend (Flutter) setup

Phase 3 added real Dart source under `frontend/lib/` (state management,
networking, auth, map wiring, voice input, timeline, history), but the
Flutter *platform scaffolding* (`web/`, `android/`, `ios/` folders,
`.metadata`, etc.) has never been generated — this repo only ever
contained `pubspec.yaml` and `lib/`.

**Important honesty note:** platform scaffolding (especially
`web/index.html`'s bootstrap script) is version-sensitive and is
generated correctly by the Flutter tool itself — fabricating it by hand
risks shipping stale boilerplate that silently breaks on your installed
Flutter version. Generate it for real:

```bash
cd frontend
flutter create --platforms=web .
```

This adds `web/` alongside the existing `lib/` and `pubspec.yaml`
without touching your source files (confirm with `git status` — only
new platform files should appear).

### Install dependencies

```bash
flutter pub get
```

### Generate real Firebase configuration

`lib/firebase_options.dart` in this repo is a deliberate stub that
throws a clear error if used as-is — no fabricated API keys were ever
placed here. Generate the real file:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Select the same Firebase project you configured for the backend in step 3.

### Run

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

The backend must be running (step 5) for this to do anything useful —
sign in, then use the mic button (or wait for the automatic Demo Mode
fallback if your browser doesn't support the Web Speech API) to generate
a mission.

### Lint and analyze

```bash
flutter analyze
```

### Known verification gap (read this before debugging blindly)

**No Flutter/Dart SDK was available in the environment this code was
written in**, and `pub.dev` was not reachable to install one. Every Dart
file here was written to match well-established, stable APIs
(`flutter_riverpod` 2.x, `google_maps_flutter` 2.x, `firebase_auth` 5.x)
as precisely as possible, and cross-checked for import-path correctness
and brace/paren balance with a custom static script — but **none of it
has been run through `flutter analyze` or an actual compiler.**

The single highest-risk file is
`lib/features/voice/web_speech_bindings.dart` (raw browser JS interop
for the Web Speech API) — smoke-test this first, in a real Chrome tab,
before relying on it for anything. Everything else (state management,
networking, models) is lower-risk since it doesn't touch raw JS interop.

Run `flutter analyze` immediately after `flutter pub get` and treat any
errors it reports as expected first-pass findings to fix, not a sign
something is fundamentally wrong with the architecture.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `ValueError: CORS_ALLOWED_ORIGINS must be set...` on startup | Missing/empty/wildcard CORS env var | Set `CORS_ALLOWED_ORIGINS` in `.env` to explicit origin(s), no `*` |
| `ModuleNotFoundError: No module named 'config'` | Running commands from repo root instead of `backend/` | `cd backend` first |
| `firebase_admin.exceptions...` on startup | Bad/missing `GOOGLE_APPLICATION_CREDENTIALS` path | Confirm the service account JSON path in `.env` is correct and the file exists |
| `pip install` dependency conflict | Manually edited version pins in `requirements.txt` | Do not change pins without re-running the resolution check described in `DECISIONS.md` — `google-genai` has strict transitive constraints on `pydantic` and `httpx` |
