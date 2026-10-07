# Flutter release workflow

- Work on `dev`, or merge a feature branch into `dev` first.
- `main` is reserved for approved releases. Only pull requests from this repository’s `dev` branch may merge into `main`.
- Never push directly to `main`, bypass protection, or disable the required release source check.
- Merging to `main`, uploading to TestFlight, or publishing a release requires explicit user authorization. These are separate actions; pushing to `dev` does not publish a build.
- Do not commit generated `.flutter-plugins-dependencies` changes unless specifically needed.

The release policy workflow uses `pull_request_target` only to inspect PR metadata. Never add checkout of PR code or execute PR-controlled code in this workflow.
