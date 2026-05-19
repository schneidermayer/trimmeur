# Development Rules

Behavior changes should add or update focused tests when the logic can be exercised outside the live app shell.

Run `./scripts/test.sh` before finishing implementation work. If you change app-bundle-affecting files, also run `./scripts/build.sh debug`.

Do not run `./scripts/build.sh prod` unless explicitly asked; production builds sign and notarize with Apple services.

The build script must continue to run tests before packaging for both `debug` and `prod`.

Keep the app as a lightweight menu-bar agent. Avoid adding windows or onboarding unless the permission flow genuinely requires it.

# Completion Workflow

After every change, once tests and the relevant build have completed successfully, commit and push the work.

After committing and pushing, install the freshly built app into `/Applications`. If `Trimmeur` is already running, kill the running process first, then copy the app bundle into `/Applications/Trimmeur.app` and start it from there.
