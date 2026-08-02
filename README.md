# Supplementary Material — CONCAPAN 2026

Supplementary material for the paper **"Power Consumption Characterization of Planar MOSFET and FinFET Technologies Across Nanometer Nodes: A Comparative HSPICE Study"** (Group 04, IEEE CONCAPAN 2026).

Includes the MATLAB scripts used to generate the power surfaces, the raw simulation data (HSPICE), and the resulting figures.

## Repository structure

```
├── matlab/
│   ├── graficar_simulaciones_temp.m   # generates power surfaces vs. temperature
│   ├── graficar_simulaciones_volt.m   # generates power surfaces vs. voltage
│   └── xlsx_to_mat.py                 # converts raw .xlsx to .mat
├── data/
│   ├── Simulaciones_MUX.mat / .xlsx
│   ├── Simulaciones_Adder.mat / .xlsx
│   └── Simulaciones_Multiplicador.mat / .xlsx
├── figures/
│   ├── TEMP/   # power surfaces vs. temperature (per circuit)
│   └── VOLT/   # power surfaces vs. voltage (per circuit)
└── requirements.txt
```

## Simulated circuits

- 2:1 multiplexer
- 3-bit ripple-carry adder
- 3-bit sequential multiplier

Each simulated in HSPICE under voltage sweeps (0.9 V–1.3 V) and temperature sweeps (–40 °C to 80 °C), across planar MOSFET (130 nm–22 nm) and FinFET (20 nm–7 nm) technologies.

## Requirements

- MATLAB (tested on R2023b or later)
- Python 3.x with dependencies in `requirements.txt` (only needed to regenerate `.mat` from `.xlsx`)

## Usage

1. Clone the repo.
2. Run `graficar_simulaciones_volt.m` or `graficar_simulaciones_temp.m` from `matlab/`, pointing to the `.mat` files in `data/`.
3. Figures are saved to `figures/VOLT/` or `figures/TEMP/` accordingly.

To regenerate the `.mat` files from the original `.xlsx` files:

```bash
pip install -r requirements.txt
python matlab/xlsx_to_mat.py
```

## Citation

If you use this material, please cite the original paper (CONCAPAN 2026, Group 04) — full reference available once the proceedings are published.

## License

To be determined (suggested: MIT for code, CC-BY for data/figures).
