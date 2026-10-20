# Contributing

Thanks for wanting to improve Perlite Flow. This file covers the local dev loop,
where to look for what, and the conventions we keep.

## Getting set up

You need:

- Flutter stable (this repo is built on the current stable channel — `flutter --version`)
- Android SDK + a JDK 21 (`$env:JAVA_HOME` on Windows, or whatever your OS uses)
- A running Perlite instance for end-to-end testing, **or** the offline
  `test/real_*.html` fixtures for parser work

```sh
flutter pub get
flutter test                     # fast sanity check
flutter analyze                  # lints (flutter_lints 6)
flutter run -d emulator-5554     # debug build
```

## Code layout and conventions

- `lib/services/perlite_client.dart` is the only place that talks HTTP.
  It returns parsed `FileNode` / `SearchResultGroup` — never raw HTML to callers.
- The DOM contract is documented in code comments. If Perlite changes the
  markup, update the tests in `test/perlite_client_test.dart` and the
  offline fixtures in `test/real_perlite_integration_test.dart` first.
- `flutter_secure_storage` for credentials, `shared_preferences` for
  non-secret settings. Do not put passwords in `SharedPreferences`.
- Material 3 only. No `MaterialApp(theme: ThemeData(...))` boilerplate —
  go through `ThemeState` so the seed + dynamic color paths stay wired.
- Use `package:material_symbols_icons/symbols.dart` for icons. Don't pull in
  `package:material_design_icons` or font-awesome just for one glyph.

## Adding a feature

1. Write the parsing logic in `perlite_client.dart`, with a unit test in
   `test/perlite_client_test.dart` covering the happy path and at least one
   shape-perversion case (missing attribute, empty list, nested span).
2. Plumb it through `app_state.dart`. Keep widget code dumb — state belongs
   in `AppState` / `ThemeState`, not inside widgets.
3. For UI work, run both light and dark mode at least once.
4. Put user-facing text in `lib/l10n/app_en.arb`, then add Chinese and
   Japanese translations in `app_zh.arb` and `app_ja.arb`.

## Testing against a real server

`integration_test/real_server_test.dart` exercises the full Dio -> parse ->
model pipeline against a live vault. Pass the server through dart defines:

```sh
flutter test integration_test\real_server_test.dart -d <device> `
  --dart-define=PERLITE_URL=https://notes.example.com `
  --dart-define=PERLITE_USER=... `
  --dart-define=PERLITE_PASSWORD=...
```

If the emulator can't resolve DNS, restart it with `-dns-server 223.5.5.5,8.8.8.8`
and wait ~30 s for `netd` to come up before running tests.

## Pull requests

- One concern per PR. If you find an unrelated bug, send it separately.
- `flutter analyze` must be clean. `flutter test` must pass.
- Include a screenshot for UI changes on both light and dark theme.
- Keep release-notes-worthy changes listed in the PR description.

## Reporting issues

Attach:

- Your Android version (`Settings → About → Android version`)
- Whether you're using a public or self-hosted Perlite (no need to share the URL)
- Logcat snippet if there's a crash (`adb logcat | grep -i perlite`)

For security issues (credential leaks, cert validation, XSS in the webview),
email the maintainer directly — do not open a public issue.

## License

AGPL-3.0. By contributing you agree to license your work under the same terms.
