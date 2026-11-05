# MACELES density scan — post-processing results (double backup)

This directory is the GitHub copy of the post-processing products of
`bench/maceles_density_scan`.

- `scan_summary.csv` — cross-state structural summary
- `c2_*.npz` — cross-state c2(r) arrays
- `states/<sim_id>/analysis.json` — per-state scalar summary
- `figures/*.png` — cross-state and per-species figures
- `state_bundles/<sim_id>.tar.gz` — **full state post-processing bundle**
  (analysis/*.npz, c1c2/*, analysis.json), same object as the Zenodo
  `states/<sim_id>.tar.gz` key

The full state bundles are therefore backed up twice: here on GitHub and on
Zenodo record `23901520`. Raw trajectories remain on Zenodo record `23901522`
(too large for git).
