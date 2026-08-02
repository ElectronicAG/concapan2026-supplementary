# Supplementary Material — CONCAPAN 2026

Material complementario del paper **"Power Consumption Characterization of Planar MOSFET and FinFET Technologies Across Nanometer Nodes: A Comparative HSPICE Study"** (Grupo 04, IEEE CONCAPAN 2026).

Incluye los scripts de MATLAB usados para generar las superficies de potencia, los datos crudos de simulación (HSPICE) y las figuras resultantes.

## Estructura del repositorio

```
├── matlab/
│   ├── graficar_simulaciones_temp.m   # genera superficies de potencia vs. temperatura
│   ├── graficar_simulaciones_volt.m   # genera superficies de potencia vs. voltaje
│   └── xlsx_to_mat.py                 # convierte .xlsx crudo a .mat
├── data/
│   ├── Simulaciones_MUX.mat / .xlsx
│   ├── Simulaciones_Adder.mat / .xlsx
│   └── Simulaciones_Multiplicador.mat / .xlsx
├── figures/
│   ├── TEMP/   # superficies de potencia vs. temperatura (por circuito)
│   └── VOLT/   # superficies de potencia vs. voltaje (por circuito)
└── requirements.txt
```

## Circuitos simulados

- Multiplexor 2:1
- Sumador ripple-carry de 3 bits
- Multiplicador secuencial de 3 bits

Cada uno simulado en HSPICE bajo barridos de voltaje (0.9 V–1.3 V) y temperatura (–40 °C a 80 °C), en tecnologías planar MOSFET (130 nm–22 nm) y FinFET (20 nm–7 nm).

## Requisitos

- MATLAB (probado en R2023b o superior)
- Python 3.x con dependencias en `requirements.txt` (solo necesario si se regenera `.mat` desde `.xlsx`)

## Uso

1. Clonar el repo.
2. Correr `graficar_simulaciones_volt.m` o `graficar_simulaciones_temp.m` desde `matlab/`, apuntando a los `.mat` en `data/`.
3. Las figuras se guardan en `figures/VOLT/` o `figures/TEMP/` según corresponda.

Para regenerar los `.mat` desde los `.xlsx` originales:

```bash
pip install -r requirements.txt
python matlab/xlsx_to_mat.py
```

## Cita

Si usás este material, citar el paper original (CONCAPAN 2026, Grupo 04) — referencia completa disponible una vez publicado el proceedings.

## Licencia

Pendiente de definir (sugerido: MIT para código, CC-BY para datos/figuras).
