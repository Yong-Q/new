# MACELES density scan — post-processing results (lightweight mirror)

This directory is the GitHub backup of the **small** post-processing products of
`bench/maceles_density_scan`. It is updated from `analysis_scan/` every 30 min
by `scripts/sync_postproc.sh`.

Contents:

- `scan_summary.csv` — cross-state structural summary
- `c2_*.npz` — cross-state c2(r) arrays
- `states/<sim_id>/analysis.json` — per-state scalar summary
- `figures/*.png` — cross-state and per-species figures

The heavy per-state arrays (`analysis/com.npz`, `intra.npz`, `profiles.npz`,
`c1c2/*`) and the complete state bundles are **not** duplicated in git; they
are archived on Zenodo:

- analysis record: `23901520` (`states/<sim_id>.tar.gz` contains the full
  state directory, including `analysis.json`)
- raw trajectories: `23901522`

This gives a double backup of the interpretable results (GitHub + Zenodo) and
a single full-size archive of the large arrays on Zenodo.
