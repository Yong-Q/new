#!/bin/bash
# Upload state bundles once each, with a remote-size check and a local ledger.
set -uo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO=$(cd -- "$HERE/.." && pwd -P)
BZA=$(cd -- "$REPO/.." && pwd -P)
A=${SCAN_ROOT:-$BZA/symmetrix-polar/bench/maceles_density_scan}
ANA=${ANA:-$A/analysis_scan}
export SCAN_ROOT="$A" ANA="$ANA"
PY=${PY:-/opt/matos-tools/conda/envs/matos-compute/bin/python}
export PYTHONPATH="$REPO:${PYTHONPATH:-}"
export ZENODO_TOKEN=${ZENODO_TOKEN:-$(cat "$BZA/.secrets/zenodo_token" 2>/dev/null)}
cd "$REPO" || exit 1
while true; do
  "$PY" - <<'PY'
import json, os, sys
from pathlib import Path
sys.path.insert(0, '/workspace/group/shared/bza/test')
from sampling.zenodo_upload import list_files, upload
A=Path(os.environ['SCAN_ROOT'])
ANA=Path(os.environ['ANA'])
ledger_path=ANA/'.zenodo_bundles.json'
ledger=json.loads(ledger_path.read_text()) if ledger_path.exists() else {}
try:
    remote=list_files('23901520')
except Exception:
    remote=None
if remote is not None:
    for b in sorted((ANA/'_bundles').glob('*.tar.gz')):
        key=f'states/{b.name}'
        sig=[b.stat().st_size,int(b.stat().st_mtime)]
        if ledger.get(b.name)==sig:
            continue
        rsize=remote.get(key)
        if rsize is not None and rsize==b.stat().st_size:
            ledger[b.name]=sig; ledger_path.write_text(json.dumps(ledger,indent=2)); continue
        if upload('23901520',key,b):
            ledger[b.name]=sig; ledger_path.write_text(json.dumps(ledger,indent=2))
            print(f'[bundles] uploaded {b.name}', flush=True)
PY
  sleep 100
done
