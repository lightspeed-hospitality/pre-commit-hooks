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

## Available hooks

- `circleci-config-validate`: Test if the CircleCI config file is well formed.
- `circleci-config-pack`: Pack the CircleCI config and build the config.yml
- `detect-secrets`: Scan for secrets committed into the repo
- `end-of-file-fixer`: Checks that all your JSON files are pretty.
- `google-java-code-format`
- `poetry-pytest`: Use poetry to create a virtual-env and run pytest
- `pretty-format-json`: Checks that all your JSON files are pretty.
- `requirements-txt-fixer`
- `shellcheck`
- `shfmt`
- `tidy-xml-format`
- `trailing-whitespace`: Trims trailing whitespace.
- `yamllint`

### Options

#### `detect-secrets`

Scan for secrets committed into the repo.

**Note**: Since detect secrets (on Yelp) seems to [not be maintained anymore](https://github.com/Yelp/detect-secrets/issues/473),
we decided to use the [IBM fork](https://github.com/IBM/detect-secrets) since at least it's actively developed. Only issue is that it's
relatively out of sync from the mainstream, but it should work fine for our needs.

- To generate a baseline of secrets:
  - Install the correct version of detect-secrets:

      ```console
      python3 -m pip install --upgrade "git+https://github.com/ibm/detect-secrets.git@0.13.1+ibm.45.dss#egg=detect-secrets"
      ```

  - Run the baseline scan: `detect-secrets scan --base64-limit 4.5 --hex-limit 3  --update .secrets.baseline`
- Set `args: ['--baseline', '.secrets.baseline']` in your pre-commit config

#### `pretty-format-json`

Checks that all your JSON files are pretty.  "Pretty"
here means that keys are sorted and indented.  You can configure this with
the following command-line options:

- `--autofix` - automatically format json files
- `--indent ...` - Control the indentation (either a number for a number of spaces or a string of whitespace).  Defaults to 2 spaces.
- `--no-ensure-ascii` preserve unicode characters instead of converting to escape sequences
- `--no-sort-keys` - when autofixing, retain the original key ordering (instead of sorting the keys)
- `--top-keys comma,separated,keys` - Keys to keep at the top of mappings.

#### `trailing-whitespace`

Trims trailing whitespace:

- To preserve Markdown [hard line-breaks](https://github.github.com/gfm/#hard-line-break)
  use `args: [--markdown-linebreak-ext=md]` (or other extensions used
  by your markdown-files).  If for some reason you want to treat all files
  as markdown, use `--markdown-linebreak-ext=*`.
- By default, this hook trims all whitespace from the ends of lines.
    To specify a custom set of characters to trim instead, use `args: [--chars,"<chars to trim>"]`.
