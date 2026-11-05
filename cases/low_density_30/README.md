# Low-density 30 cases (6 species × 5 densities)

Scope: **only r00–r04 for H2O, NH3, CH4, C2H4, C2H6, CO2** (30 cases).
High-density r05–r09 is not part of this assignment.

Status (2026-11-05):

- **2 running old** — wait for them to finish, do not rerun:
  `H2O r00`, `C2H4 r00`
- **28 not started** — run with exact EOS data:
  `manifest_28_run_now.csv`
- `manifest_30_exact.csv` — all 30 exact cases (including the 2 running old,
  for reference/mapping).
- `cases_parameters.csv` — precise parameters and status for all 30.
- `mapping_actual_to_exact.csv` — actual (submitted/old) sim_id and density ↔
  exact EOS sim_id and density, sorted by density ascending.

Exact data root:

    /workspace/group/shared/bza/symmetrix-polar/bench/maceles_density_scan_prl_exact/data/<species>/rXX_<rho>.lammps

Command template for the 28:

    python sampling/les_batch.py \
      --manifest cases/low_density_30/manifest_28_run_now.csv \
      --outroot <workdir>/samples --run --no-analyze --resume \
      --equil-steps 200000 --steps 2000000 --dump-every 1000 \
      --lmp <lmp> --model <model> --cubin <cubin> --ld-library-path <libs>

Run one state per GPU; stage each finished `samples/<exact_sim_id>/` under the
matching `shard_X/attempt-04/samples/<exact_sim_id>/` for post-processing and
Zenodo upload.
