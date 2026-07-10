from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from projects.Waveguide.example.reproduction import annulus_tm


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parent / "generated")
    args = parser.parse_args()
    annulus_tm(args.output)


if __name__ == "__main__":
    main()
