# Build status

Implementation started 9 October 2026.

## Implemented

Four worlds, 32 interactive quests, six reusable mechanics, offline saves, XP/coins, decorative unlocks, topic badges, eight plant profiles and growing beds, encyclopedia/glossary, curated Buzz, camera preview/result adapter, accessibility, parent PIN/time limits, optional sound, reminders and Supabase backend source.

Dark mode is available in Settings → Appearance: Light, Dark or Use device setting. Theme changes apply immediately and persist with the local save. Sites hosts the browser build; current deployment is managed through `.openai/hosting.json`.

Optional adult email/password accounts connect to `nntizitzglpyfepnmasp`. The public Site retains guest play. The account screen offers sign-up, sign-in and sign-out with local form validation, confirmation messaging and server-owned sessions. Cloud sync is disabled in this auth-only deployment, as requested. The connected administrative Supabase account cannot access this project; migrations/functions have not been deployed there.

## Verified locally

- Flutter 3.47.6 analysis: no issues.
- 17 Flutter tests passed, including a UI test completing all 32 quests, persistence, engine behavior, photo metadata stripping, demo/reset behavior, appearance switching/persistence/device brightness, auth SDK confirmation/session/error behavior and 390px/180% text accessibility.
- Six Deno contract/security-boundary tests passed; all five functions type-check.
- PostgreSQL migration/RLS/idempotency/prerequisite/currency/deletion suite passed in PGlite with Auth/Storage fixtures.
- Content validator: 32 quests, eight plants, 11 source references.
- Android debug APK built successfully at `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`.
- Web build succeeded; manual browser QA completed a honey lesson and verified progress survived reload. Planting, watering, harvesting and collecting a plant card worked. Phone and tablet layouts and accessible world navigation were checked.
- GitHub CI built Android and iOS simulator successfully in the initial source run. Its integration-test formatting issue was corrected. Mobile and backend jobs passed on source commit `65a8799`; the final accessibility revision and native simulator flows are checked by the linked PR's current workflow.
- Tracked-file and Git-history secret scans passed.

## Delivery and next checks

Origin: https://github.com/5iber7/Nurturio- ; branch `codex/nurturio-build`.
Source and documentation are pushed. Draft PR: https://github.com/5iber7/Nurturio-/pull/1 . Native runtime CI results are recorded in the PR checks; do not infer runtime success from compilation alone.

Local Android emulator runtime was not attempted because host virtualization is unavailable. CI now runs native quest flows in Android and iOS simulators. Physical-device camera/reminder/secure-storage checks remain open.

Supabase Auth settings were read successfully using the client publishable key: email sign-up is enabled and email confirmation is required. A live invalid-password probe returned `invalid_credentials`. Positive signup/email-confirmation delivery remains a user acceptance check; no real verification emails were sent by this development session. Set the production Site URL/redirect allowlist and configure custom SMTP for general public email delivery. The unrelated connected project has not been changed. Live AI and child cloud services remain disabled. See docs/RELEASE_BLOCKERS.md. No production store or game-data backend publication has occurred.
