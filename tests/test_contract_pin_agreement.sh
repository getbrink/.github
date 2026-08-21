#!/usr/bin/env bash
# Prover for assert-authority-derived.sh. Each arm mutates a TRACKED workflow,
# so all of them run over a copy under a temp dir; the live tree is never
# touched.
#
# The arms deliberately spell the defect three different ways. A prover that
# injects it in the gate's own vocabulary proves the grep matches itself.
set -uo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d); trap 'rm -rf "${WORK}"' EXIT
fail() { echo "META-TEST FAIL: assert-authority-derived did not catch $1"; exit 1; }

WF_REL=".github/workflows/contract-pin-agreement.yml"

stage() {   # stage <name> -> prints the staged root
    local d="${WORK}/$1"
    mkdir -p "${d}"
    cp -R "${REPO_ROOT}/.github" "${REPO_ROOT}/scripts" "${d}/"
    printf '%s' "${d}"
}

CLEAN=$(stage clean)
bash "${CLEAN}/scripts/assert-authority-derived.sh" "${CLEAN}" >/dev/null \
    || { echo "PREFLIGHT FAIL: the unmutated copy does not pass its own gate"; exit 3; }

# Arm A — the env: spelling, an input named as the thing it supplies.
A=$(stage a)
python3 - "${A}/${WF_REL}" <<'PY'
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
grep -Eq '^[[:space:]]*AUTHORITATIVE:[[:space:]]*\$\{\{' "${A}/${WF_REL}" \
    || { echo "PREFLIGHT FAIL: arm A mutation did not apply"; exit 3; }
bash "${A}/scripts/assert-authority-derived.sh" "${A}" >/dev/null 2>&1 \
    && fail "the authoritative version taken as a workflow input (env: spelling)"

# Arm B — a shell assignment inside run:, an input named nothing like it, and
# the real derivation left behind as a comment so a substring check still sees
# it. This is the arm the first version of the gate passed.
B=$(stage b)
python3 - "${B}/${WF_REL}" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
s = s.replace('      manifest_path:\n',
    '      pinned_version:\n'
    '        description: "The version brink ships."\n'
    '        required: true\n'
    '        type: string\n'
    '      manifest_path:\n', 1)
s = s.replace('          AUTHORITATIVE=$(bash brink/scripts/contract-version.sh)\n',
    '          # was: AUTHORITATIVE=$(bash brink/scripts/contract-version.sh)\n'
    '          AUTHORITATIVE="${{ inputs.pinned_version }}"\n', 1)
p.write_text(s)
PY
grep -Fq 'AUTHORITATIVE="${{ inputs.pinned_version }}"' "${B}/${WF_REL}" \
    || { echo "PREFLIGHT FAIL: arm B mutation did not apply"; exit 3; }
command -v actionlint >/dev/null 2>&1 && { actionlint "${B}/${WF_REL}" >/dev/null \
    || { echo "PREFLIGHT FAIL: arm B workflow does not parse"; exit 3; }; }
bash "${B}/scripts/assert-authority-derived.sh" "${B}" >/dev/null 2>&1 \
    && fail "a caller-supplied version assigned in the shell (= spelling)"

# Arm C — the derivation kept and executed, then quietly overwritten.
C=$(stage c)
python3 - "${C}/${WF_REL}" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
s = s.replace('      manifest_path:\n',
    '      pinned_version:\n'
    '        description: "The version brink ships."\n'
    '        required: true\n'
    '        type: string\n'
    '      manifest_path:\n', 1)
s = s.replace('          AUTHORITATIVE=$(bash brink/scripts/contract-version.sh)\n',
    '          AUTHORITATIVE=$(bash brink/scripts/contract-version.sh)\n'
    '          AUTHORITATIVE="${{ inputs.pinned_version }}"\n', 1)
p.write_text(s)
PY
grep -Fq 'AUTHORITATIVE="${{ inputs.pinned_version }}"' "${C}/${WF_REL}" \
    || { echo "PREFLIGHT FAIL: arm C mutation did not apply"; exit 3; }
bash "${C}/scripts/assert-authority-derived.sh" "${C}" >/dev/null 2>&1 \
    && fail "a second assignment overwriting the derived version"

echo "test_contract_pin_agreement: 3 stale-input spellings caught"
