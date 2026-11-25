#!/bin/bash
# Upload state bundles once each, with a remote-size check and a local ledger.
set -uo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO=$(cd -- "$HERE/.." && pwd -P)
BZA=$(cd -- "$REPO/.." && pwd -P)
A=${SCAN_ROOT:-$BZA/symmetrix-polar/bench/maceles_density_scan}
ANA=${ANA:-$A/analysis_scan}
export SCAN_ROOT="$A" ANA="$ANA"
# Record to use for state bundles; when full (Zenodo caps at 100 files) the
# uploader opens a fresh draft and records it in the local ledger.
export BUNDLE_RECORD=${ANA_RECORD:-23901520}
# Only bundles newer than this ISO timestamp go to a repointed record, so old
# rounds already archived elsewhere are never duplicated.
export BUNDLES_SINCE_TS=${BUNDLES_SINCE_TS:-0}
PY=${PY:-/opt/matos-tools/conda/envs/matos-compute/bin/python}
export PYTHONPATH="$REPO:${PYTHONPATH:-}"
export ZENODO_TOKEN=${ZENODO_TOKEN:-$(cat "$BZA/.secrets/zenodo_token" 2>/dev/null)}
cd "$REPO" || exit 1
while true; do
  "$PY" - <<'PY'
import json, os, sys
from pathlib import Path
sys.path.insert(0, '/workspace/group/shared/bza/test')
from sampling.zenodo_upload import create_draft, list_files, upload
A=Path(os.environ['SCAN_ROOT'])
ANA=Path(os.environ['ANA'])
RECORD=os.environ.get('BUNDLE_RECORD','23901520')
SINCE=float(os.environ.get('BUNDLES_SINCE_TS','0') or 0)
MAX_FILES=95
ledger_path=ANA/'.zenodo_bundles.json'
ledger=json.loads(ledger_path.read_text()) if ledger_path.exists() else {}
recs=ledger.setdefault('__records__', [RECORD])
def save():
    ledger_path.write_text(json.dumps(ledger,indent=2))
try:
    remote=list_files(recs[-1]) if recs else None
except Exception:
    remote=None
if remote is not None:
    # Roll over before the 100-file per-record cap is hit.
    if len(remote)>=MAX_FILES:
        rec=create_draft('analysis', {'title': 'MACELES PRL density scan — per-state analysis bundles (continued)'})
        recs.append(rec['id']); save()
        print(f'[bundles] record full at {len(remote)} files; continued in {rec["id"]}', flush=True)
        try:
            remote=list_files(recs[-1])
        except Exception:
            remote=None
if remote is not None:
    for b in sorted((ANA/'_bundles').glob('*.tar.gz')):
        if SINCE and b.stat().st_mtime < SINCE:
            continue
        key=f'states/{b.name}'
        sig=[b.stat().st_size,int(b.stat().st_mtime)]
        if ledger.get(b.name)==sig:
            continue
        rsize=remote.get(key)
        if rsize is not None and rsize==b.stat().st_size:
            ledger[b.name]=sig; save(); continue
        if len(remote)>=MAX_FILES:
            rec=create_draft('analysis', {'title': 'MACELES PRL density scan — per-state analysis bundles (continued)'})
            recs.append(rec['id']); save()
            print(f'[bundles] record full; continued in {rec["id"]}', flush=True)
            try:
                remote=list_files(recs[-1])
            except Exception:
                remote={}
        if upload(recs[-1],key,b):
            ledger[b.name]=sig; save()
            remote[key]=b.stat().st_size
            print(f'[bundles] uploaded {b.name} -> {recs[-1]}', flush=True)
PY
  sleep 100
done
