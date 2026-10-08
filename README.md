# Nurturio

**Learn by growing. Discover by doing.** An offline-first Flutter game for iOS and Android, with an optional web preview and Supabase backend.

## What is implemented

- Four illustrated worlds and 32 interactive lessons: honey, olive oil, chicken care, and gardening.
- Six reusable interaction templates, learning checks, compressed waits, saved progress, XP, coins, collections and earned decorations.
- Offline encyclopedia, eight plant profiles, glossary, reference notes and curated Ask Buzz.
- Camera/gallery previews with metadata stripping; identification adapter and result flow are disabled in production by default.
- Optional music, action sounds, read-aloud, reduced motion, parent PIN, session limits, local export/deletion and native readiness reminders.
- Light, Dark and device-following appearance in Settings, persisted locally.
- Supabase migrations, row ownership, atomic sync/reward merge, authenticated functions, export/deletion and gated Gemini integration.

This is a working initial release candidate, not a claim of app-store approval. Check [BUILD_STATUS.md](BUILD_STATUS.md) and [docs/RELEASE_BLOCKERS.md](docs/RELEASE_BLOCKERS.md) for actual verification and pending external setup.

## Run the mobile app

Install Flutter **3.47.6**. Android needs Java 21, Android SDK 36 and NDK 28.2.13676358. iOS needs a Mac with Xcode and the platform tools required by Flutter.

```sh
cd apps/mobile
flutter pub get
flutter run
```

No cloud account or credentials are needed for offline gameplay. Select an emulator or attached device with `flutter devices`, then `flutter run -d DEVICE_ID`.

On this development computer Flutter is at `C:\Users\sal3h\develop\flutter\bin\flutter.bat`; use its absolute path if Flutter is not on PATH. Locally installed build tools live in ignored `.tools/` and are not part of the repository.

## Developer demo

On a fresh local save, `flutter run --dart-define=DEMO_MODE=true` seeds clearly labeled example progress. Existing progress is preserved; release builds cannot auto-seed this demo.

## Optional browser preview

```sh
cd apps/mobile
dart compile js -O2 web/drift_worker.dart -o web/drift_worker.dart.js
flutter build web
python -m http.server 5180 --directory build/web
```

Open `http://localhost:5180`. SQLite's WebAssembly binary and the Drift worker are included for local browser persistence. The [public browser app](https://nurturio.jauntybud16.chatgpt.site) uses Sites; `.openai/hosting.json` binds this repository to that Site. Copy the tested `apps/mobile/build/web` output into ignored `dist/` before packaging through the Sites source workflow. Never publish privileged cloud credentials.

## Checks

```sh
node scripts/validate-content.mjs
node scripts/secret-scan.mjs
cd apps/mobile
flutter analyze
flutter test
flutter test integration_test/quest_flow_test.dart -d DEVICE_ID
```

From the repository root:

```sh
deno check --config supabase/functions/deno.json supabase/functions/*/index.ts
deno test --config supabase/functions/deno.json --allow-env --allow-read supabase/functions/tests
deno run --config scripts/deno.json --allow-read --allow-env scripts/test-database.ts
```

The PostgreSQL harness exercises migrations and RLS using PGlite with Auth/Storage schema fixtures. It does **not** replace testing a deployed Supabase service. See [backend setup](docs/AI_SETUP.md).

## Content and assets

`apps/mobile/assets/content` contains runtime packs. `scripts/build-content.mjs` is the authored source; edit it and regenerate using `node scripts/build-content.mjs`. Validate afterward. The bundled processes use qualitative real-world timings rather than unsupported fixed biological numbers. Eight plants have individual care profiles; deeper cultivar simulations are future content work.

Add a topic pack with an existing template, register it in `manifest.json`, and update the generator/validator, source registry and server approved-context module. A new fundamental interaction requires a new template. See [architecture](docs/ARCHITECTURE.md) and [assets](docs/ASSETS.md).

## Optional Supabase configuration

Nurturio's selected project is `nntizitzglpyfepnmasp`; the published build connects optional adult email/password accounts. Guest play remains public, and progress stays local. Game-data deployment is deferred. See [account configuration](docs/AI_SETUP.md) for email confirmation URLs and custom SMTP; positive email delivery must be checked on the real project. No unrelated remote project has been modified. For the local stack with Docker, run `supabase --help` and the relevant subcommand help for your installed CLI, then:

```sh
supabase start
supabase db reset
supabase functions serve --env-file .env.local
```

Create a local public-config JSON file (ignored; use a name such as `public-config.local.json` and add it to your local excludes) containing `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`. Run Flutter with `--dart-define-from-file=PATH`. Never include Gemini or privileged Supabase credentials in that file. The server requires `CLOUD_ACCESS_APPROVED=true` for cloud operations. Adult email OTP templates must include the email token for the in-app code flow.

Deploy migrations/functions only after selecting and reviewing the correct project. Child cloud services and live Gemini use remain gated. Do not enable the Gemini Developer API in this all-ages app under its currently reviewed terms.

## GitHub and licensing

Destination: `https://github.com/5iber7/Nurturio-`. Development branch: `codex/nurturio-build`. CI checks source and creates build artifacts after push. Store publishing and signing are separate steps. See [GitHub setup](docs/GITHUB_SETUP.md).

Original source has no open-source license grant yet; the owner should select one. Nunito uses SIL OFL, and dependency licenses remain applicable. No paid assets, user photos, secrets or signing files belong in this repository.

