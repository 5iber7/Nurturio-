# Build status

Implementation started 9 October 2026.

## Implemented

Four worlds, 32 interactive quests, six reusable mechanics, offline saves, XP/coins, decorative unlocks, topic badges, eight plant profiles and growing beds, encyclopedia/glossary, curated Buzz, camera preview/result adapter, accessibility, parent PIN/time limits, optional sound, reminders and Supabase backend source.

Dark mode is available in Settings → Appearance: Light, Dark or Use device setting. Theme changes apply immediately and persist with the local save. Sites hosts the browser build; current deployment is managed through `.openai/hosting.json`.

### 3D modernization — 10 October 2026

The village, four topics and lessons now use original bundled glTF dioramas with an animated farmer guide, bees and chickens, PBR materials, camera rotation/zoom and local lighting. Growing beds display eight mature plant models and two earlier growth stages. Buzz has a 3D bee. Both themes have updated typography, colors, navigation and card surfaces. Settings preserves reduced motion and adds a persisted lighter-graphics option. All four content packs, 32 quests, guest access and local saves remain in place.

Actual verification for this revision: Flutter 3.47.6 analysis has no issues; all 17 tests pass, including completion of all 32 lessons; Khronos glTF Validator reports no errors in all 16 models; content validation passes. Android debug APK and JavaScript web builds succeed. Six Deno tests, five function type-checks and the PostgreSQL/PGlite suite pass. Local 390×844 browser QA confirms WebGL rendering, drag-to-orbit, world-card navigation, light/dark presentation, lighter graphics and preference persistence after reload. Models and the renderer are bundled locally (approximately 1.2 MB for models); no remote model/CDN dependency was introduced.

These are stylized 3D nature scenes. Headless tests use the original artwork fallback and do not validate the GPU renderer. Physical Android/iPhone rendering, pinch gestures, memory/thermal performance and iOS runtime remain acceptance checks. The Android compile result is not a device runtime claim. Existing TTS optional-WASM/Kotlin migration warnings remain; the shipped browser build uses JavaScript.

Optional adult email/password accounts connect to `nntizitzglpyfepnmasp`. The public Site retains guest play. The account screen offers sign-up, sign-in and sign-out with local form validation, confirmation messaging and server-owned sessions. Cloud sync is disabled in this auth-only deployment, as requested. The connected administrative Supabase account cannot access this project; migrations/functions have not been deployed there.

## Verified locally

### Card and choice fixes — 10 October 2026

Activity choices now use wrapping cards: select an item, then select its destination, or long-press and drag. Completed items stay visible, incorrect choices receive feedback, repeated taps cannot apply to another item, and progress is shown explicitly. Learning checks use the same readable cards. Settings/onboarding/plant selectors use scrollable choice panels instead of cramped dropdowns. Growing beds preview the selected plant before planting. Village/Buzz and collection card rows stack their actions to fit narrow screens; card Material/ink rendering and clipping were corrected. Continuous pouring stops when the interaction ends.

Previous native CI exposed `setState() called after dispose()` in model_viewer_plus 1.10.0. The preserved Apache-2.0 source is now vendored with guarded async initialization and immediate cleanup of late-bound local servers, plus corrected shadow/RGBA attributes. Native scene gestures no longer eagerly consume vertical page scrolling. A deterministic disposal-race regression passes. The previous iOS runtime job timed out while its simulator booted; its boot allowance has been increased, but that is not an iOS runtime pass.

The current Flutter suite passes 20 tests, including all 32 lessons, independently labeled accessible choices, wrong/repeat choice actions, the viewer disposal race and all main card layouts/learning checks at 320px with 200% text. Flutter analysis has no issues. The JavaScript web build and Android debug build succeed. Local 390×844 browser QA completed matching with wrong/correct choices, a learning check with wrong/correct answers, and selected Mint through the plant panel, verified its new 3D preview and planted the correct bed. Content (32 quests/eight plants) and all 16 glTF assets validate. Six Deno security tests and the PostgreSQL/PGlite suite pass. See current PR checks for the new native renderer run; physical Android/iPhone gesture/performance acceptance remains open.

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
