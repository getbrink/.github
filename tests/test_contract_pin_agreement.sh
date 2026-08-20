#!/usr/bin/env bash
# Prover for assert-authority-derived.sh. The mutation edits a TRACKED workflow,
# so it runs over a copy under a temp dir; the live tree is never touched.
set -uo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d); trap 'rm -rf "${WORK}"' EXIT
fail() { echo "META-TEST FAIL: assert-authority-derived did not catch $1"; exit 1; }

cp -R "${REPO_ROOT}/.github" "${REPO_ROOT}/scripts" "${WORK}/"
WF="${WORK}/.github/workflows/contract-pin-agreement.yml"

bash "${WORK}/scripts/assert-authority-derived.sh" "${WORK}" >/dev/null \
    || { echo "PREFLIGHT FAIL: the unmutated copy does not pass its own gate"; exit 3; }

python3 - "${WF}" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
s = s.replace('      manifest_path:\n',
    '      authoritative_version:\n'
    '        description: "The version brink ships."\n'
    '        required: true\n'
    '        type: string\n'
    '      manifest_path:\n', 1)
s = s.replace('          MANIFEST_PATH: ${{ inputs.manifest_path }}\n',
    '          MANIFEST_PATH: ${{ inputs.manifest_path }}\n'
    '          AUTHORITATIVE: ${{ inputs.authoritative_version }}\n', 1)
s = s.replace('          AUTHORITATIVE=$(bash brink/scripts/contract-version.sh)\n', '', 1)
p.write_text(s)
PY

grep -Eq '^[[:space:]]*AUTHORITATIVE:[[:space:]]*\$\{\{[[:space:]]*inputs\.' "${WF}" \
    || { echo "PREFLIGHT FAIL: the mutation did not apply"; exit 3; }
command -v actionlint >/dev/null 2>&1 && { actionlint "${WF}" >/dev/null \
    || { echo "PREFLIGHT FAIL: the mutated workflow does not parse"; exit 3; }; }

bash "${WORK}/scripts/assert-authority-derived.sh" "${WORK}" >/dev/null 2>&1 \
    && fail "the authoritative version taken as a workflow input"
echo "test_contract_pin_agreement: stale-input mutation caught"
