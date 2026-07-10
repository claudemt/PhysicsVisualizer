from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from projects.CrystalOpticsBoundary.example.reproduction import typical_example


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parent / "generated")
    args = parser.parse_args()
    typical_example(args.output)


if __name__ == "__main__":
    main()
