from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from projects.ChladniFigures.example.reproduce_support import reproduce_annulus_eigen_mode


def reproduce(output_dir: str | Path | None = None):
    return reproduce_annulus_eigen_mode(output_dir)


if __name__ == "__main__":
    reproduce()
