# Reproducible toolchain

- Flutter 3.47.6 / Dart 3.13.5, pinned in `.flutter-version`.
- Deno 2.9.7; function dependencies are pinned in `deno.json` and `deno.lock`.
- Supabase CLI used locally: 2.120.0. Commands were checked using help before use.
- Java 21, Android platform/build tools 36, NDK 28.2.13676358.
- Package constraints in `pubspec.yaml` and resolved transitive versions in `pubspec.lock`.
- `model_viewer_plus` 1.10.0 and `webview_flutter` 4.14.1 provide bundled glTF rendering. Browser builds load the local module declared in `web/index.html`; native configuration permits the local asset server.
- Node asset checks use Khronos `gltf-validator` 2.0.0-dev.3.10, pinned in `package-lock.json`; install with `npm ci`. The original model generator has no package dependencies.
- GitHub Actions references are pinned to verified release commit SHAs.

Flutter's generated native projects determine current minimum targets. Check camera, secure storage, notifications and TTS on real devices before release. JavaScript web compilation succeeds; the TTS package currently emits optional WASM dry-run compatibility warnings. The browser preview uses JavaScript compilation, not experimental full-app WASM.

No package upgrade is automatically assumed safe. Re-run content, engine, persistence, backend and native checks after dependency updates. Review dependency licenses through Flutter's generated license registry before publishing.
