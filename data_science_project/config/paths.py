"""
Centralized project paths.

Notes:
- No side effects at import (does not create directories).
- Paths are computed relative to the package directory.
"""

from pathlib import Path

# Package root: .../data_science_project
PACKAGE_ROOT = Path(__file__).resolve().parents[1]

# Repo root: one level above the package
REPO_ROOT = PACKAGE_ROOT.parent

# Common directories
DATA_DIR = REPO_ROOT / "data"
APP_LOGS_DIR = DATA_DIR / "logs"

# Config directory (this module's directory)
CONFIG_DIR = PACKAGE_ROOT / "config"

__all__ = [
    "REPO_ROOT",
    "PACKAGE_ROOT",
    "CONFIG_DIR",
    "DATA_DIR",
    "APP_LOGS_DIR",
]