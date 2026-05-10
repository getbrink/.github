#!/usr/bin/env bash
# Pre-merge sanity check for the org-wide reusable release workflow.
#
# Validates the workflow YAML via `actionlint` (preferred) and `act --list`
# (fallback) — both parse the workflow without executing it.
#
# Full sign + attest verification (cosign keyless OIDC + SLSA provenance +
# Rekor) requires a real GitHub Actions runner with a GitHub-minted OIDC
# token. `act` does not emulate OIDC; testing the full path requires
# pushing a `vX.Y.Z-rcN` candidate tag to one of the per-repo callers and
# observing the in-workflow self-verify step succeed.
#
# Prerequisites (maintainer laptop):
#   - actionlint   (https://github.com/rhysd/actionlint)
#     OR
#   - act          (https://github.com/nektos/act)
#
# Run:
#   ./tests/test_release_workflow.sh
#
# Exit codes:
#   0 = workflow YAML parses cleanly
#   1 = workflow YAML has a lint or parse error
#   3 = preflight failure (neither actionlint nor act on PATH)

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKFLOW_FILE="${REPO_ROOT}/.github/workflows/release.yml"

if [ ! -f "${WORKFLOW_FILE}" ]; then
    echo "ERROR: reusable workflow not at ${WORKFLOW_FILE}" >&2
    exit 1
fi

HAS_ACTIONLINT=0
HAS_ACT=0
command -v actionlint >/dev/null 2>&1 && HAS_ACTIONLINT=1
command -v act        >/dev/null 2>&1 && HAS_ACT=1

if [ "${HAS_ACTIONLINT}" -eq 0 ] && [ "${HAS_ACT}" -eq 0 ]; then
    echo "ERROR: install actionlint (preferred) or act before running." >&2
    echo "  brew install actionlint    # or" >&2
    echo "  brew install act" >&2
    exit 3
fi

if [ "${HAS_ACTIONLINT}" -eq 1 ]; then
    echo "Running actionlint on ${WORKFLOW_FILE}..."
    actionlint "${WORKFLOW_FILE}"
    echo "OK: actionlint passed."
fi

if [ "${HAS_ACT}" -eq 1 ]; then
    echo "Running 'act --list' on ${WORKFLOW_FILE}..."
    act --workflows "${WORKFLOW_FILE}" --list >/dev/null
    echo "OK: act parsed the workflow."
fi

cat <<'EOF'

----
Workflow YAML parses cleanly.

This script does NOT exercise the full sign + attest flow because act
cannot emulate GitHub Actions OIDC. Full end-to-end verification runs
against a real GHA runner triggered by a v0.0.0-rcN candidate tag push:

    git tag v0.0.0-rc1 && git push origin v0.0.0-rc1
    gh run watch --repo getbrink/<image-repo>

The in-workflow `Cosign self-verify` step verifies sign + SBOM + SLSA
attestations against the just-pushed digest. Failures there surface
identity / OIDC / Rekor drift before the release is announced.
EOF

exit 0
