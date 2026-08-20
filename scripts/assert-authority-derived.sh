#!/usr/bin/env bash
# The authoritative contract version must be READ from the brink checkout. A
# workflow that accepts it as an input certifies whatever the caller says.
set -uo pipefail
ROOT=${1:-$(cd "$(dirname "$0")/.." && pwd)}
WF="${ROOT}/.github/workflows/contract-pin-agreement.yml"
[ -f "${WF}" ] || { echo "ERROR: no workflow at ${WF}" >&2; exit 3; }
if grep -Eq '^[[:space:]]*AUTHORITATIVE:[[:space:]]*\$\{\{[[:space:]]*inputs\.' "${WF}"; then
    echo "ERROR: ${WF} takes the authoritative version from a workflow input" >&2; exit 1
fi
grep -Fq 'bash brink/scripts/contract-version.sh' "${WF}" || {
    echo "ERROR: ${WF} does not derive the version from brink/scripts/contract-version.sh" >&2; exit 1; }
echo "authority is derived from the brink checkout"
