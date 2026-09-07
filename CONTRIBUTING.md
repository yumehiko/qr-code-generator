# Contributing

## Local commands

Run commands from the repository root, or invoke the scripts from any working
directory. Each script resolves the repository root itself.

```bash
scripts/test.sh                 # Swift package tests
swift build -c release          # release executable
scripts/build-app.sh            # app bundle in dist/
scripts/build-release.sh        # optimized app bundle in dist/
scripts/sign-app.sh             # ad-hoc sign a release bundle
scripts/create-dmg.sh           # package the release bundle in dist/
scripts/create-iconset.sh       # regenerate assets/icons/AppIcon.icns
```

`scripts/integration-test.sh` runs the test suite and a release build. The app
bundle scripts place all generated bundles and disk images in `dist/`, which is
ignored by Git.

## Repository layout

- `Sources/` and `Tests/`: Swift package code, tests, and runtime resources.
- `scripts/`: local build, test, signing, icon, and packaging commands.
- `assets/icons/`: editable icon source (`Icon.ai`) and generated ICNS icon.
- `config/macos/`: bundle metadata and signing entitlements.
- `docs/`: development documentation and historical audit records.

## Submission checks

- Run `scripts/test.sh` or `swift test`.
- Run an appropriate build command for the changed files.
- Keep credentials, personal details, and local absolute paths out of commits,
  Issues, and pull requests.
