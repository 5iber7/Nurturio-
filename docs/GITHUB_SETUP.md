# GitHub delivery

Repository: https://github.com/5iber7/Nurturio-
Branch: `codex/nurturio-build` based on the repository's existing `main` commit.

Local Git authentication can push even though the connected read-only GitHub tool reports no write permission. No credentials have been copied into project files. Source history preserves the initial README commit. No force push is used.

CI has read-only repository permissions. It builds web, Android debug and unsigned iOS simulator artifacts; backend checks use deterministic tests and PostgreSQL fixtures. No production deployment runs on push.

For signed release automation, add signing credentials to protected GitHub environments and create a separate manual workflow. Never commit signing files or secret environment values. Review CI results and the draft PR before merging.
