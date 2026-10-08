# Decisions

- Flutter + Flame, Riverpod, go_router, Drift and Supabase follow the brief.
- Offline gameplay has no dependency on sign-in or remote provisioning.
- Live AI fails closed. Gemini Developer API is unsuitable for the intended under-18 audience under the terms reviewed in the brief. Curated Buzz is the launch fallback.
- Hand-drawn procedural scene artwork avoids unlicensed external assets and stays consistent across worlds.
- The developer application may also compile for web to provide a convenient preview; native iOS/Android projects remain the primary deliverable.
- No remote Supabase database is changed until a project has been explicitly selected.

