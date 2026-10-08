# Supabase and AI setup

The backend is implemented as migrations plus five Edge Functions. Nurturio's selected project is `nntizitzglpyfepnmasp`. Only client Auth is connected in the current release; game-data functions and migrations are not deployed. The administrative connector cannot access this project. The unrelated project found in the current connection has not been modified.

## Optional account configuration

The public build uses email/password sign-up and sign-in. Supply only `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` through an ignored JSON file and `--dart-define-from-file=PATH`. Do not include service-role or provider keys. Adult accounts are optional; guest play and local saves remain available.

In Authentication → URL Configuration, set Site URL and allowed redirect URL to `https://nurturio.jauntybud16.chatgpt.site`. Keep email confirmations enabled. Supabase's default SMTP restricts delivery to project-team addresses; configure custom SMTP in the dashboard for general public signup. Do not place SMTP credentials in client configuration. Verify confirmation delivery and first sign-in using a real test account before advertising unrestricted account availability.

`CLOUD_SYNC_ENABLED` defaults to false. Enable it only after deploying and validating game-data functions and their server authorization. Signing in currently does not upload the local save. Email confirmation/session/sign-out/error behavior is tested using the real Supabase SDK with a controlled HTTP transport; live successful email delivery is not inferred from those tests.

1. Install Docker and a compatible Supabase CLI for the full local stack.
2. Run local start/reset, apply migrations and seed content, and test authentication with two accounts.
3. Configure adult email OTP delivery and templates. Verify expiry, retries and reauthentication.
4. Set server-only `CLOUD_ACCESS_APPROVED=true` only for a reviewed adult cloud deployment.
5. Deploy functions with user-JWT verification enabled and test missing, forged, expired and deleted-user credentials.

## Live AI gate

The reviewed Gemini Developer API terms prohibit clients directed toward or likely accessed by under-18s: https://ai.google.dev/gemini-api/terms. Nurturio is an all-ages product. A paid plan, parent PIN or parental consent does not remove that provider restriction.

Keep `AI_DEPLOYMENT_APPROVED=false` and `AI_PROVIDER=disabled`. To enable an eligible future deployment, document the actual contract, permitted ages, region, billing, retention and privacy review; then provision explicit server-managed profile permissions. Do not assume an alternative Google channel is automatically eligible.

Server-only variables: `GEMINI_API_KEY`, `GEMINI_MODEL`, `AI_PROVIDER`, `AI_DEPLOYMENT_APPROVED`, `APP_ENV`; privileged Supabase secrets stay in function secrets. Model IDs are deliberately configurable and unset, not guessed. Verify current model availability and schema support before a live test.

Developer mock: server `AI_PROVIDER=mock`, `APP_ENV=dev`, with authorization and the feature gate still enforced. Flutter `--dart-define=AI_MOCK=true` works only in debug mode, labels fixtures honestly, and never uploads the photo. Release builds cannot enable this fixture path.

Image requests are bounded, parsed/re-encoded, and processed transiently. Model output is schema-validated and never certifies edibility. Prompts are versioned server-side. Minimal database-backed quotas are atomic; no raw image/chat logging is implemented. Add project-level billing alerts and a global provider budget/circuit breaker before live production activation.

The local PGlite test validates PostgreSQL policies/transactions with Auth and Storage schema fixtures. Actual Supabase Auth, Storage service APIs, Edge Function deployment and live Gemini have not been exercised without a selected project/eligible credentials. These checks remain deployment acceptance requirements.
