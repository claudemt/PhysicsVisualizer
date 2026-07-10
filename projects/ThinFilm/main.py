from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.main_window import run_project_from_file

if __name__ == "__main__":
    raise SystemExit(run_project_from_file(__file__))
