# 30 exact runs — final 4-card split (A/B/C/D, v2)

The 30 exact-EOS complement cases are run as **four independent veMLP tasks**,
one per A100-80G card (queue004, `ml.pni2.3xlarge`). Each task reads
`manifest.csv` in manifest order, i.e. **low density → high density** within the
group.

## Why this split

The old `_est` column was wrong (it over-predicted high-density runs and
under-predicted the very dilute ones). The v2 split uses a timing model fitted
to 17 real runs on the same hardware:

    t_step [s] = 7.4515e-4 * N_atoms^0.3993 + 1.5100e-8 * V_A3^1.1087

(fit residuals: mean 5.8 %, max 15.5 %). Total run time per case is
`2.2e6 steps × t_step × 1.03` (200 k equilibration + 2 M production),
which reproduces the measured wall times of H2O r00 (59.3 h), NH3 r05–r09
(10.5–11.2 h) and C2H6 r05–r08 (15.5–15.8 h).

Constraints used for the split:

1. no card finishes much earlier than another (time balance);
2. each group gets a spread of densities (≈2–3 cases in each density tercile,
   mean density rank ≈15 of 30);
3. CO2 ρ=0.001867 (`CO2_rho0.001867_T463.6K`, the case the 24-server cannot
   finish) is **inside** a group, not a separate task;
4. group sizes 7–8 cases.

The optimum is bounded below by the single slowest case: C2H6 ρ=0.000261
(100.4 h) forces its group to ≥163.6 h with the six smallest remaining cases.

## Predicted times (hours, 2.2 M steps)

| Group | cases | predicted total | mean density rank | terciles (low/mid/high) |
|---|---|---|---|---|
| A | 8 | **148.1 h (6.17 d)** | 14.9 | 2 / 3 / 3 |
| B | 7 | **167.9 h (7.00 d)** | 16.7 | 2 / 3 / 2 |
| C | 7 | **149.0 h (6.21 d)** | 15.1 | 3 / 2 / 2 |
| D | 8 | **150.3 h (6.26 d)** | 15.4 | 3 / 2 / 3 |

Makespan 167.9 h ≈ 7.0 d; spread 19.8 h ≈ 0.8 d. Total ≈ 615 GPU-hours.

## Group A — includes CO2 ρ=0.001867

| sim_id | density (molec/Å³) | predicted h |
|---|---|---|
| NH3_rho0.000522_T618.2K | 0.000522 | 50.4 |
| CO2_rho0.001867_T463.6K | 0.001867 | 18.6 |
| NH3_rho0.004292_T618.2K | 0.004292 | 13.7 |
| C2H4_rho0.004496_T430.4K | 0.004496 | 15.2 |
| C2H4_rho0.005547_T430.4K | 0.005547 | 14.4 |
| NH3_rho0.008062_T618.2K | 0.008062 | 11.7 |
| C2H4_rho0.008700_T430.4K | 0.008700 | 13.3 |
| H2O_rho0.020362_T986.4K | 0.020362 | 10.7 |

## Group B — includes the slowest case C2H6 ρ=0.000261

| sim_id | density (molec/Å³) | predicted h |
|---|---|---|
| C2H6_rho0.000261_T465.4K | 0.000261 | 100.4 |
| CO2_rho0.003330_T463.6K | 0.003330 | 13.9 |
| CO2_rho0.006254_T463.6K | 0.006254 | 11.3 |
| CH4_rho0.007364_T290.5K | 0.007364 | 11.4 |
| CO2_rho0.007717_T463.6K | 0.007717 | 10.8 |
| CO2_rho0.010642_T463.6K | 0.010642 | 10.1 |
| CO2_rho0.012104_T463.6K | 0.012104 | 9.9 |

## Group C — includes CO2 ρ=0.000405

| sim_id | density (molec/Å³) | predicted h |
|---|---|---|
| CO2_rho0.000405_T463.6K | 0.000405 | 62.6 |
| C2H4_rho0.002393_T430.4K | 0.002393 | 19.0 |
| C2H6_rho0.004036_T465.4K | 0.004036 | 17.1 |
| C2H6_rho0.004980_T465.4K | 0.004980 | 16.2 |
| CH4_rho0.005969_T290.5K | 0.005969 | 11.9 |
| H2O_rho0.012982_T986.4K | 0.012982 | 11.3 |
| H2O_rho0.017902_T986.4K | 0.017902 | 10.9 |

## Group D — includes CH4 ρ=0.000386

| sim_id | density (molec/Å³) | predicted h |
|---|---|---|
| CH4_rho0.000386_T290.5K | 0.000386 | 54.1 |
| C2H6_rho0.002149_T465.4K | 0.002149 | 21.3 |
| CH4_rho0.003177_T290.5K | 0.003177 | 14.0 |
| H2O_rho0.005601_T986.4K | 0.005601 | 13.8 |
| C2H4_rho0.007649_T430.4K | 0.007649 | 13.5 |
| CH4_rho0.010155_T290.5K | 0.010155 | 10.9 |
| H2O_rho0.010522_T986.4K | 0.010522 | 11.8 |
| CH4_rho0.011551_T290.5K | 0.011551 | 10.8 |

## Execution notes

- Group D waits until the old C2H4 r00 run on shard 3 exits (~15 h), because
  the account admission ceiling is 4 concurrent GPU tasks. The other three
  groups start immediately.
- Restart/resume: `write_restart prod_<step>.restart` every 50 000 steps,
  `read_restart` on relaunch, dump `append yes`; the 2 M production run is
  chunked so a killed task resumes from the last checkpoint.
- Raw trajectories and analysis products are mirrored to Zenodo
  (records 23901522 / 23901520) and GitHub `Yong-Q/new` in 100 s cycles.
