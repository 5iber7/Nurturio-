# Architecture

The mobile app owns its offline state. Flutter renders screens, bundled GLB assets provide animated 3D dioramas through `WorldView`/model-viewer, Flame drives pouring/rhythm controls, and reusable templates handle sorting, matching, placement and sequencing. Riverpod supplies a single initialized controller; go_router guards onboarding, parent access and session breaks.

`core/content.dart` decodes bundled versioned packs. `game/engine/process_engine.dart` is independent of UI and uses an injected clock. `core/database.dart` stores aggregate saves and a durable outbox in SQLite through Drift. Writes are serialized and snapshots copied before queuing; saved steps and action identities survive interruption. Timers recompute on resume. Device clocks remain untrusted offline.

Core progression never contacts a server. Curated Buzz retrieves authored facts. Discover re-encodes images and strips metadata; its optional adapter calls only authenticated Supabase functions. Production AI is disabled unless an eligible provider arrangement has been separately configured.

Supabase stores private adult-account progress. The `sync_snapshot` RPC delegates to a narrowly privileged private function that validates caller ownership, locks the profile, merges unique completed quest IDs, recomputes rewards/decorations, and deduplicates operation IDs. RLS protects reads, and direct client ledger writes are revoked. This privileged boundary is deliberate: an unprivileged client cannot write authoritative coin balances.

On revision conflicts, completed quests and decorations merge; the server retains existing settings and active processes. The client keeps a recoverable local process rather than rewinding ongoing play. An offline modified client can still claim plausible learning completion: there is no competitive, paid or redeemable economy.

Cloud profiles use local UUIDs and can be imported through explicit sync after adult sign-in. Current sync is manually triggered. The outbox survives network interruption; it is not a guarantee of automatic background upload. Pictures and chats are not cloud-synced.

Adding content requires a pack, source references and existing interaction configurations. Truly new mechanics require template code. All four launch worlds share the same engine. Plant field-guide entries are independently authored; release content still requires expert review.

The public Sites browser build uses Drift's WASM SQLite module and worker for local saves. It ships the model-viewer JavaScript and all models with the app. Native model viewers serve bundled assets over loopback without requiring an external network. Browser first load still requires the hosted build. Reduced motion stops automatic model animation; `scene3d=false` retains the original painters. Unsupported native desktop/headless platforms use the painter fallback. WebGL/native WebView behavior must be validated separately from headless widget tests.
