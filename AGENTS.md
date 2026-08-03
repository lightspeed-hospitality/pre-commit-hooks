#Overview
Pre-commit hooks for our various services

# Agent notes

## Release a new version

1. Land the change on the default branch.
2. Optionally dogfood first by pinning consumers to a commit SHA instead of a tag:

   ```yaml
   - repo: https://github.com/lightspeed-hospitality/pre-commit-hooks
     rev: <commit-sha>
     hooks:
       - id: circleci-config-validate
   ```

3. Create an annotated version tag (`vX.Y.Z`, e.g. `v0.7.50`) from the release commit.
4. Push the tag and create a GitHub release from it:
   https://github.com/lightspeed-hospitality/pre-commit-hooks/releases/new
5. Consumers pin with `rev: vX.Y.Z` in `.pre-commit-config.yaml`.

`rev` may be a tag or a commit SHA. See `README.md` for consumer setup and available hooks.
