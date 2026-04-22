# Western Malabar

Flutter commerce app with Supabase-backed checkout, admin picking/packing flows, and a small Node-based local print server.

## Repo Structure

- `lib/`: Flutter app source
- `test/`: Flutter tests
- `supabase/`: backend SQL/functions assets
- `server.js`: local Node print server

## Local Setup

### Flutter app

```bash
flutter pub get
flutter run
```

### Print server

```bash
npm ci
npm start
```

## Quality Gates

Run these before opening a PR:

```bash
dart format lib test
flutter analyze
flutter test
```

## Repo Hygiene Rules

- Do not commit `node_modules/`
- Do not commit local temp files or print output
- Commit `pubspec.lock` intentionally for the Flutter app
- Commit `package-lock.json` intentionally for the print server
- Keep unrelated changes out of the same PR

See [CONTRIBUTING.md](C:/Users/leoge/western_malabar/CONTRIBUTING.md) for the working standard.
