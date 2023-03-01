# Pre-Commit-Hooks

[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![CircleCI](https://circleci.com/gh/lightspeed-hospitality/pre-commit-hooks.svg?style=svg&circle-token=ad9a82293e27bd8777c3e8b3f81ddbdb95b217f3)](https://circleci.com/gh/lightspeed-hospitality/pre-commit-hooks)

A collection of useful git hooks for use with [pre-commit](https://pre-commit.com/).

## Use `pre-commit` in other repos

Create or append to your `.pre-commit-config.yaml` configuration:

```yaml
- repo: https://github.com/lightspeed-hospitality/pre-commit-hooks
  rev: v0.6.0
  hooks:
  - id: circleci-config-pack
  - id: circleci-config-validate
  - id: poetry-pytest
```

## Release a new version

### Test Changes

Before publishing a new version (with a tag) you can test changes on this repository in other projects by using a commit SHA

```yaml
- repo: https://github.com/lightspeed-hospitality/pre-commit-hooks
  rev: 4f707bc9dfeb75d70c4c37ebde63f8dc334f126d
  hooks:
  - id: circleci-config-pack
  - id: circleci-config-validate
  - id: poetry-pytest
```

`rev` can be either a tag or a commit SHA

### Create a new Tag/Release

Create a new git tag with the new version and [create a release based on the tag](https://github.com/lightspeed-hospitality/pre-commit-hooks/releases/new).

## Available hooks

### From [pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks/tree/v4.1.0#hooks-available)

All hooks are defined in [.pre-commit-hooks-yaml](.pre-commit-hooks-yaml). For further information and usage [check this list of available hooks here](https://github.com/pre-commit/pre-commit-hooks/tree/v4.1.0#hooks-available).

### Hooks added in this repo

- `black`: Python Code Formatter
- `ruff`: An extremely fast Python linter
- `circleci-config-validate`: Test if the CircleCI config file is well formed.
- `circleci-config-pack`: Pack the CircleCI config and build the config.yml
- `detect-secrets`: Scan for secrets committed into the repo
- `flake8`: Tool For Python Style Guide Enforcement
- `google-java-code-format`
- `isort`: Python import sorting
- `poetry-pytest`: Use poetry to create a virtual-env and run pytest
- `poetry-run`: Use poetry to run any check command (pyright, pylint, ...)
- `shellcheck`
- `shfmt`
- `yamllint`
- `checkstyle`: runs `mvn checkstyle:check`
- `prettier-xml`: Formats XML using prettier, requires `node` to be initialized. Requires dummy `package.json` in the root of the `pre-commit-hooks` repo for successful initialization

### Options

#### `detect-secrets`

Scan for secrets committed into the repo.

**Note**: Since detect secrets (on Yelp) seems to [not be maintained anymore](https://github.com/Yelp/detect-secrets/issues/473),
we decided to use the [IBM fork](https://github.com/IBM/detect-secrets) since at least it's actively developed. Only issue is that it's
relatively out of sync from the mainstream, but it should work fine for our needs.

- To generate a baseline of secrets:
  - Install the correct version of detect-secrets:

      ```console
      python3 -m pip install --upgrade "git+https://github.com/ibm/detect-secrets.git@0.13.1+ibm.56.dss#egg=detect-secrets"
      ```

  - Run the baseline scan: `detect-secrets scan --base64-limit 4.5 --hex-limit 3  --update .secrets.baseline`
- Set `args: ['--baseline', '.secrets.baseline']` in your pre-commit config
