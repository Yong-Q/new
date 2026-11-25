#!/usr/bin/env bash
# Supervisor for the exact-EOS complement campaign only.
#
# The main zenodo_loops.sh already runs the original scan loops; this script
# adds the same watch / Zenodo mirror / trajectory upload / bundle upload set
# for <bza>/symmetrix-polar/bench/maceles_density_scan/exact_campaign
# without touching the running original loops.
#
#   scripts/zenodo_loops_exact.sh
set -uo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO=$(cd -- "$HERE/.." && pwd -P)
BZA=${BZA:-$(cd -- "$REPO/.." && pwd -P)}
PY=${PY:-/opt/matos-tools/conda/envs/matos-compute/bin/python}
EXACT_ROOT=${EXACT_ROOT:-$BZA/symmetrix-polar/bench/maceles_density_scan/exact_campaign}
# 23901520 / 23901522 are full (Zenodo caps a record at 100 files); dense
# rounds v4/v5 continue in fresh drafts with their own state bundles.
ANA_RECORD=${ANA_RECORD:-24519705}
TRAJ_RECORD=${TRAJ_RECORD:-24519703}
BUNDLES_SINCE=${BUNDLES_SINCE:-2026-11-20}
LOGS=${LOGS:-$EXACT_ROOT/analysis_scan}
WATCH=${WATCH:-100}
SCAN_INTERVAL=${SCAN_INTERVAL:-100}

if [[ -z "${ZENODO_TOKEN:-}" && -f "$BZA/.secrets/zenodo_token" ]]; then
    ZENODO_TOKEN=$(cat "$BZA/.secrets/zenodo_token")
fi
export ZENODO_TOKEN PYTHONPATH="$REPO:${PYTHONPATH:-}"
cd "$REPO" || exit 1
mkdir -p "$LOGS"

supervise() {
    local name=$1; shift
    while true; do
        echo "[sup $(date -u +%H:%M:%S)] start $name" >> "$LOGS/supervisor.log"
        "$@" >> "$LOGS/$name.log" 2>&1
        echo "[sup $(date -u +%H:%M:%S)] $name exited rc=$?; restart in 60 s" \
            >> "$LOGS/supervisor.log"
        sleep 60
    done
}

supervise watch_exact "$PY" -m sampling.scan_watch \
    --root "$EXACT_ROOT" --out "$LOGS" --interval "$SCAN_INTERVAL" --keep-traj &
supervise mirror_exact "$PY" -m sampling.zenodo_upload \
    --root "$LOGS" --kind analysis --record-id "$ANA_RECORD" \
    --bundle-states --no-bundles --bundles-figures-only --watch "$WATCH" \
    --bundles-since "$BUNDLES_SINCE" &
supervise traj_exact "$PY" -m sampling.zenodo_batch_traj \
    --root "$EXACT_ROOT" --record-id "$TRAJ_RECORD" --batch 3 --watch "$WATCH" \
    --max-files 95 --archive-dir "$EXACT_ROOT/traj_archive" &
supervise bundles_exact env SCAN_ROOT="$EXACT_ROOT" ANA="$LOGS" \
    ANA_RECORD="$ANA_RECORD" \
    BUNDLES_SINCE_TS="$(date -u -d "$BUNDLES_SINCE" +%s)" \
    "$HERE/upload_bundles.sh" &
wait
