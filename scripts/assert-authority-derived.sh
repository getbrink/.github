#!/usr/bin/env bash
# The authoritative contract version must be READ from the brink checkout. A
# workflow that accepts it as an input certifies whatever the caller says.
#
# Three assertions, because the defect has more than one spelling: an env:
# mapping uses a colon, a shell assignment inside run: uses an equals sign, and
# either can name the input anything at all.
set -uo pipefail
ROOT=${1:-$(cd "$(dirname "$0")/.." && pwd)}
WF="${ROOT}/.github/workflows/contract-pin-agreement.yml"
[ -f "${WF}" ] || { echo "ERROR: no workflow at ${WF}" >&2; exit 3; }

# Comments come off first. This file's own rationale names the shapes it
# refuses, and so does the workflow's; a whole-file match reads the prose.
CODE=$(sed 's/[[:space:]]*#.*$//' "${WF}")

DERIVED=$(grep -cF 'AUTHORITATIVE=$(bash brink/scripts/contract-version.sh)' <<<"${CODE}")
[ "${DERIVED}" -eq 1 ] || {
    echo "ERROR: ${WF} does not derive AUTHORITATIVE from brink/scripts/contract-version.sh exactly once (found ${DERIVED})" >&2
    exit 1; }

# Nothing else may write it. A second assignment after the derivation wins.
ASSIGNMENTS=$(grep -cE '(^|[^A-Za-z_])AUTHORITATIVE[[:space:]]*[:=]' <<<"${CODE}")
[ "${ASSIGNMENTS}" -eq 1 ] || {
    echo "ERROR: ${WF} assigns AUTHORITATIVE ${ASSIGNMENTS} times; only the derivation may" >&2
    exit 1; }

# manifest_path addresses a file in the caller; it is not the value being
# graded. Any other input is the caller feeding the checker its own answer.
STRAY=$(grep -oE '\$\{\{[[:space:]]*inputs\.[A-Za-z0-9_]+' <<<"${CODE}" \
        | sed 's/.*inputs\.//' | sort -u | grep -vx 'manifest_path' || true)
[ -z "${STRAY}" ] || {
    echo "ERROR: ${WF} reads workflow inputs other than manifest_path: $(tr '\n' ' ' <<<"${STRAY}")" >&2
    exit 1; }

echo "authority is derived from the brink checkout"
