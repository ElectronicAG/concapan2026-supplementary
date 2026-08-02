"""
Converts Simulaciones_*.xlsx to .mat files (MATLAB).

Usage:
    python xlsx_to_mat.py                         # search xlsx in current directory
    python xlsx_to_mat.py path/to/files           # directory with xlsx
    python xlsx_to_mat.py a.xlsx b.xlsx c.xlsx   # specific files

Dependencies:
    pip install pandas openpyxl scipy
"""

import sys
import re
from pathlib import Path

import pandas as pd
import numpy as np
from scipy.io import savemat


def sanitize(name: str) -> str:
    """Converts string to valid MATLAB variable name."""
    name = re.sub(r"[^a-zA-Z0-9_]", "_", name)
    if name and name[0].isdigit():
        name = "_" + name
    return name or "_var"


def sheet_to_struct(df: pd.DataFrame) -> dict:
    """
    Converts DataFrame to dict compatible with savemat.
    - Numeric columns -> double arrays
    - Text columns    -> cell arrays (object array of strings)
    """
    struct = {}
    for col in df.columns:
        key = sanitize(col)
        series = df[col]
        if pd.api.types.is_numeric_dtype(series):
            struct[key] = series.to_numpy(dtype=np.float64, na_value=np.nan)
        else:
            # cell array of strings; NaN -> empty string
            struct[key] = np.array(
                [v if isinstance(v, str) else "" for v in series],
                dtype=object,
            )
    return struct


def xlsx_to_mat(xlsx_path: Path, out_dir: Path) -> Path:
    sheets = pd.read_excel(xlsx_path, sheet_name=None)

    mat_data = {}
    for sheet_name, df in sheets.items():
        var_name = sanitize(sheet_name)
        # Avoid name collisions
        if var_name in mat_data:
            var_name += "_2"
        mat_data[var_name] = sheet_to_struct(df)

    out_path = out_dir / (xlsx_path.stem + ".mat")
    savemat(str(out_path), mat_data, do_compression=True)
    return out_path


def resolve_inputs(args: list[str]) -> list[Path]:
    if not args:
        return sorted(Path(".").glob("*.xlsx"))

    paths: list[Path] = []
    for a in args:
        p = Path(a)
        if p.is_dir():
            paths.extend(sorted(p.glob("*.xlsx")))
        elif p.suffix.lower() == ".xlsx":
            paths.append(p)
        else:
            print(f"[WARN] ignored (not .xlsx or directory): {a}")
    return paths


def main():
    inputs = resolve_inputs(sys.argv[1:])

    if not inputs:
        print("No .xlsx files found.")
        sys.exit(1)

    for xlsx in inputs:
        out = xlsx_to_mat(xlsx, xlsx.parent)
        print(f"  {xlsx.name}  →  {out.name}")

    print("Done.")


if __name__ == "__main__":
    main()