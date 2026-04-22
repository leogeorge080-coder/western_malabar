# Contributing

## Baseline Standards

This repo should be treated as an app repo with reproducible builds and a clean release path.

Required before merging:

1. Run `flutter pub get`
2. Run `dart format lib test`
3. Run `flutter analyze`
4. Run `flutter test`
5. Manually test the affected flows

## Git Hygiene

Keep commits focused. Do not mix unrelated feature, refactor, formatting, and generated-file changes in one PR.

Never commit:

- `node_modules/`
- local temp files
- print output or runtime-generated artifacts
- secret files such as `.env.local`

Commit intentionally:

- `pubspec.lock` for the Flutter app
- `package-lock.json` for the Node print server

Generated platform/plugin files should only be committed when they are intentionally changed as part of dependency or platform configuration updates.

## Branch Discipline

- Use short-lived branches
- Rebase or merge frequently from the main branch
- Keep PRs reviewable in size

## Release Discipline

Before a release build:

1. Confirm `git status` is clean
2. Confirm CI is green
3. Confirm checkout, admin picking, packing, and order history flows manually
4. Confirm environment variables are set correctly for the target environment
5. Tag the release only from a clean, reviewed commit
