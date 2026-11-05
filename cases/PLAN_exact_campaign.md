# Exact-EOS campaign after the current running states finish

## Current state (2026-11-05)

- **4 running old** — let them finish, do not rerun:
  `H2O r00`, `NH3 r09`, `C2H4 r00`, `C2H6 r08`
- **5 done old** — keep, map to exact points:
  `NH3 r05/r07/r08`, `C2H6 r06/r07`
- **2 lost old** — rerun with exact data:
  `NH3 r06`, `C2H6 r05`
- **49 queued old** — run with exact data.

The 9 old states that stay old map to the exact table via
`mapping_old_stayed_9.csv`.

## Exact campaign (51 cases)

- `manifest_28_unstarted_exact.csv` — low half r00–r04, 6 species, excluding
  the 2 running old states (`H2O r00`, `C2H4 r00`).
- `manifest_23_high_remaining_exact.csv` — high half r05–r09, excluding the
  5 done old and 2 running old states; includes the 2 lost exact reruns.
- `manifest_51_exact_campaign.csv` — the union, sorted by density ascending.
- `manifest_60_exact.csv` — full 60-case exact manifest (reference).

Exact data root (regenerated; rigid-molecule rescale, bonds preserved):

    /workspace/group/shared/bza/symmetrix-polar/bench/maceles_density_scan_prl_exact/data/<species>/rXX_<rho>.lammps

Command template:

    python sampling/les_batch.py \
      --manifest cases/manifest_28_unstarted_exact.csv \
      --outroot <workdir>/samples --run --no-analyze --resume \
      --equil-steps 200000 --steps 2000000 --dump-every 1000 \
      --lmp <lmp> --model <model> --cubin <cubin> --ld-library-path <libs>

After a state finishes, stage the whole `samples/<exact_sim_id>/` under the
matching `shard_X/attempt-04/samples/<exact_sim_id>/` so the analysis and
Zenodo loops pick it up. The old state dirs with lost trajectories remain but
have no `traj.dump*`, so they are skipped.
