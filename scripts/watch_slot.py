#!/usr/bin/env python3
"""Watch for the shard-3 slot to free and drop a D_READY marker.

The old C2H4 r00 run on shard 3 is the only task that can free a MatOS
admission slot for group D before the exact groups finish days from now.
``meta.json`` appears only after LAMMPS finished, the trajectory was gzipped
and hashed; les_batch then skips the remaining ``skipped_not_run`` rows and
the task exits seconds later.

The marker cannot submit the task itself (submission goes through the MatOS
MCP tool), but it makes the hand-off deterministic and timestamped.
"""
from __future__ import annotations

import json
import time
from datetime import datetime, timezone
from pathlib import Path

SCAN = Path("/workspace/group/shared/bza/symmetrix-polar/bench/maceles_density_scan")
RUN = SCAN / "shard_3/attempt-04/samples/C2H4-PRL-T430.3-r00-0.000291/run"
META = RUN.parent / "meta.json"
MARK = Path("/workspace/group/shared/bza/.tmp/D_READY")
LOG = SCAN / "exact_campaign/analysis_scan/slot_watch.log"


def log(msg: str) -> None:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line, flush=True)
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with open(LOG, "a") as fh:
        fh.write(line + "\n")


def main() -> None:
    marker_written = False
    last_progress = 0
    while True:
        try:
            if META.exists():
                d = json.loads(META.read_text())
                if not marker_written:
                    MARK.write_text(json.dumps({
                        "ready_at": datetime.now(timezone.utc).isoformat(),
                        "meta_status": d.get("status"),
                        "traj": d.get("traj"),
                        "traj_gz_bytes": d.get("traj_gz_bytes"),
                        "timing": d.get("timing"),
                    }, indent=1))
                    log("D_READY: shard3 C2H4 meta.json written "
                        f"(status={d.get('status')}) -> submit group D now")
                    marker_written = True
            else:
                out = RUN / "stdout.log"
                if out.exists():
                    age = time.time() - out.stat().st_mtime
                    step = 0
                    try:
                        import re
                        m = re.findall(r"^\s+(\d+)\s+[\d.]+\s+-?[\d.]+\s*$",
                                       out.read_text(errors="ignore"), re.M)
                        if m:
                            step = int(m[-1])
                    except Exception:
                        pass
                    if step != last_progress:
                        last_progress = step
                    elif age > 1800 and not marker_written:
                        log(f"WARNING: shard3 stdout idle {age/60:.0f} min "
                            f"at step {step} (possible stall)")
        except Exception as exc:                 # noqa: BLE001
            log(f"error: {type(exc).__name__}: {exc}")
        time.sleep(60)


if __name__ == "__main__":
    main()
