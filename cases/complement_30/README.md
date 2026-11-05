# 24-server complement — 30 exact runs

The 24-server runs 24 jobs = 6 molecules × r09/r06/r03/r01
(ρ* = 0.6700 / 0.4533 / 0.2367 / 0.0922).

This folder covers the **30 remaining exact runs**:

- 36 states are outside the 24-server set (r00, r02, r04, r05, r07, r08 for
  6 species).
- 7 of those 36 are already finished/running on the old data and are only
  mapped, not rerun:
  - done: NH3 r05, NH3 r07, NH3 r08, C2H6 r07
  - running: H2O r00, C2H4 r00, C2H6 r08
- 1 of the 36 is the lost C2H6 r05 — rerun exact.
- CO2 r01 (ρ* = 0.0922) is in the 24-server set but will not finish within
  its 7.4-day limit (~13.6 days needed), so it is added here.

Count: 36 − 7 + 1 = **30 exact runs**.

Files:
- `manifest_30_exact.csv` — the 30 runs, sorted by exact density ascending
- `mapping_old_7.csv` — the 7 old done/running states mapped to exact points

Exact data root:
`/workspace/group/shared/bza/symmetrix-polar/bench/maceles_density_scan_prl_exact/data/`

Run command template:

    python sampling/les_batch.py \
      --manifest cases/complement_30/manifest_30_exact.csv \
      --outroot <workdir>/samples --run --no-analyze --resume \
      --equil-steps 200000 --steps 2000000 --dump-every 1000 \
      --lmp <lmp> --model <model> --cubin <cubin> --ld-library-path <libs>
