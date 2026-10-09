# Nurturio development

Read NURTURIO_BUILD_PROMPT.md, BUILD_STATUS.md and IMPLEMENTATION_PLAN.md before continuing.

Preserve offline gameplay and all four content packs. Flutter/Flame is the mobile stack; Supabase is the backend. Keep provider and privileged keys server-side, use versioned content and caller ownership checks, and keep live AI disabled unless its intended-audience eligibility has been established.

Use Flutter 3.47.6 and the committed lockfiles. Run `node scripts/validate-content.mjs`, Flutter analysis/tests, and relevant Deno/PostgreSQL checks. Update the build status with actual evidence. Do not claim native device or cloud validation based only on unit tests.

Source changes should be committed on the development branch. Keep secrets, signing files, private configs, tool installations and build outputs out of Git. Do not overwrite unrelated user changes or modify an unrelated remote Supabase project.
