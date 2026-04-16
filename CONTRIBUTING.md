# Contributing to Brink

Thank you for considering a contribution.

## Before you start

- Read the [Code of Conduct](CODE_OF_CONDUCT.md).
- For substantial changes, open an issue first to discuss the approach.

## Development setup

Each repository has its own setup instructions in its `README.md`. The four primary repos:

- [`brink`](https://github.com/getbrink/brink) — Go control plane + proto contract
- [`brink-python`](https://github.com/getbrink/brink-python) — Python data plane
- [`brink-docs`](https://github.com/getbrink/brink-docs) — Docusaurus documentation site
- [`.github`](https://github.com/getbrink/.github) — this repo (org templates)

## Pull request process

1. Fork the relevant repo and create a feature branch.
2. Make your changes with tests.
3. Ensure CI passes (lint, build, tests).
4. Open a PR using the template.
5. Address review feedback.
6. A maintainer will merge once approved.

## Proto changes

PRs touching `proto/**` files require explicit approval from the contract steward in addition to normal code review. `buf lint` and `buf breaking` must pass.
