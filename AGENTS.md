# Development Rules

Behavior changes should add or update focused tests when the logic can be exercised outside the live app shell.

Run `./scripts/test.sh` before finishing implementation work. If you change app-bundle-affecting files, also run `./scripts/build.sh debug`.

Do not run `./scripts/build.sh prod` unless explicitly asked; production builds sign and notarize with Apple services.

Do not run `./scripts/release_github.sh` unless explicitly asked; it creates and pushes a git tag and publishes a GitHub release.

The build script must continue to run tests before packaging for both `debug` and `prod`.

Keep the app as a lightweight menu-bar agent. Avoid adding windows or onboarding unless the permission flow genuinely requires it.

# Completion Workflow

After every change, once tests and the relevant build have completed successfully, commit and push the work.

After committing and pushing, install the freshly built app into `/Applications`. If `Trimmeur` is already running, kill the running process first, then copy the app bundle into `/Applications/Trimmeur.app` and start it from there.

# Versioning and Releases

The app starts at version `1.0`. Debug builds should derive versions as `<latest-tag-version>-<commits since latest tag>`, for example `1.0-15` when there are 15 commits after `v1.0`.

Production release builds use the plain release version, for example `1.0`. The app menu must display the version in the quit item, for example `Quit Trimmeur 1.0`.

Every release must create and push a matching `v<version>` git tag. Use `scripts/release_github.sh <version>` for GitHub releases so the tag and uploaded precompiled zip stay aligned.
