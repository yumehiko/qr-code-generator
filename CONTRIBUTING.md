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
```

`scripts/integration-test.sh` runs the test suite and a release build. The app
bundle scripts place all generated bundles and disk images in `dist/`, which is
ignored by Git.

## Repository layout

- `Sources/` and `Tests/`: Swift package code, tests, and runtime resources.
- `scripts/`: local build, test, signing, and packaging commands.
- `assets/icons/`: bundled ICNS icon used by app bundle builds.
- `config/macos/`: bundle metadata and signing entitlements.
- `docs/`: development documentation, Core Image research, and historical audit records.

## Maintainer release setup

The release workflow runs only when a `v*` tag points to a commit reachable
from `main`. It uses the protected GitHub Actions environment named `release`.
Create that environment and require an appropriate reviewer before storing its
secrets, so a tag does not receive signing credentials without approval.

Set the repository variable `MACOS_BUNDLE_ID` to the registered production
bundle identifier. It must not use the checked-in `com.example` placeholder.
Add these `release` environment secrets; use base64 text with no line wraps for
the two binary/key files:

- `DEVELOPER_ID_CERTIFICATE_P12_BASE64`: Developer ID Application certificate
  exported with its private key as a `.p12` file.
- `DEVELOPER_ID_CERTIFICATE_PASSWORD`: password used when exporting that `.p12`.
- `APPSTORE_CONNECT_API_KEY_P8_BASE64`: App Store Connect API key `.p8` file
  authorized for notarization.
- `APPSTORE_CONNECT_KEY_ID`: the API key ID.
- `APPSTORE_CONNECT_ISSUER_ID`: the App Store Connect issuer ID.

Do not put any of these values in the repository, Issues, pull requests, or
workflow logs. The workflow creates a temporary keychain and files on its
runner, deletes them at the end, and fails before publishing if a setting is
missing or notarization fails.

For the first release, create the Developer ID Application certificate in the
Apple Developer account, create an App Store Connect API key, set the variable
and environment secrets, then create a `vMajor.Minor.Patch` tag such as `v1.2.3`
on `main`.
The workflow builds arm64 and x86_64 executables, combines them into a universal
app, signs with Hardened Runtime and a secure timestamp, notarizes and staples
the app, then packages, notarizes, staples, and verifies the DMG before creating
the GitHub Release. If notarization fails, inspect the `notarytool` result in
the private workflow log, correct the reported signing issue, and use a new
release tag; no release is created by the failed run.

Apple references: [Developer ID signing](https://developer.apple.com/developer-id/),
[notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow),
and [distribution signing](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac).

## Submission checks

- Run `scripts/test.sh` or `swift test`.
- Run an appropriate build command for the changed files.
- Keep credentials, personal details, and local absolute paths out of commits,
  Issues, and pull requests.
