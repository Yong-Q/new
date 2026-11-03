# MACELES post-processing

Turns finished MACELES trajectories into the c1/c2 and structural dataset used
to train / test classical-DFT functionals.

Input per state (produced by the MD side): a LAMMPS dump
(`id mol type x y z fx fy fz`, 0.5 ps frames) plus `meta.json`.

## What is computed

| output | content |
|---|---|
| `c1c2/f1`, `c1c2/f2` | PRL-format profiles: `rho`, `Vext`, `mu`; `r`, `c2(r)`, `c2(k)` |
| `analysis/profiles.npz` | pair RDF, bond-length distribution, P2, tetrahedral order |
| `analysis/pairs.npz` | **every element pair** `g_ab(r)`, spherical-harmonic anisotropy `a1(r)`, `a2(r)`, first-shell `cos(theta_z)` |
| `analysis/intra.npz` | all bond lengths / bond angles / dihedrals (labelled by element combination), molecular axes, rank-2 rotational correlation |
| `analysis/com.npz` | mass-weighted centre of mass of every molecule, every frame, plus the COM mean-square displacement |
| `analysis.json` | scalar summary per state |
| `scan_summary.csv`, `figures/` | cross-state table and plots (c2(r) vs density, g(r), trends) |

Geometry is species-generic: connectivity from covalent radii, labels from the
element symbols.  Checked against known geometries —

```
H2O   O-H 0.972 A   H-O-H 105.6 deg
NH3   N-H 1.02      H-N-H 106.3
CH4   C-H 1.09      H-C-H 109.47
C2H4  C-C 1.33      C-C-H 121.7   H-C-C-H 0/180
C2H6  C-C 1.52      C-C-H 111.2   H-C-C-H 0/+-120
CO2   C-O 1.18      O-C-O 180 (linear)
```

## Usage

```bash
pip install -r requirements.txt

# one pass over everything that is finished
python -m sampling.scan_analysis --root <scan_root> --out <scan_root>/analysis_scan

# keep watching: analyse each new state, refresh the aggregates
python -m sampling.scan_watch --root <scan_root> --interval 900

# mirror to Zenodo (draft stays editable; publish at the end)
python -m sampling.zenodo_upload --root <analysis_scan> --record-id <id> \
    --bundle-states --watch 1800
python -m sampling.zenodo_batch_traj --root <scan_root> --record-id <id> \
    --batch 3 --archive-dir <scan_root>/traj_archive
```

`scripts/zenodo_loops.sh` supervises all three loops and restarts anything that
dies.

## Files

| file | role |
|---|---|
| `scan_analysis.py` | per-state analysis + cross-state aggregation and figures |
| `pair_correlations.py` | all-pair g(r), spherical-harmonic anisotropy, first-shell orientation |
| `intramolecular.py` | bonds / angles / dihedrals, molecular axes, rotational correlation |
| `scan_watch.py` | watches a running scan, analyses finished states |
| `zenodo_upload.py` | Zenodo mirror (new InvenioRDM records API) |
| `zenodo_batch_traj.py` | bounded-batch trajectory upload with archive + rollover |
| `cdft_dataset.py` | PRL/PNAS c1/c2 extraction (`process_bulk`, `write_prl_f1/f2`) |
| `analyze_traj_orientation.py` | water orientation / H-bond / RDF quick look |
| `les_c1c2.py`, `les_batch.py` | MD driver and batch runner that produce the dumps |
