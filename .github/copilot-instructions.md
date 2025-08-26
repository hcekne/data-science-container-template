# AI Assistant Coding Guidelines

Goal: Generate professional Python code that is modular, testable, and production-friendly.

Core rules
- Keep modules short: ≤200 lines.
- Keep functions short: single responsibility, clear name, docstring, type hints (prefer ≤25 lines).
- No side effects at import. Execution only under `if __name__ == "__main__":` or via a CLI.
- Prefer composition over inheritance. Extract helpers early.
- Add/extend unit tests for all new logic.

Style
- Python 3.12+. Follow PEP 8 and PEP 257; use type hints everywhere.
- Use pathlib (not os.path).
- No print for diagnostics. Use logging (see below).
- Handle errors explicitly; raise clear, actionable exceptions.


Configuration
- Centralize paths in `data_science_project.config.paths`. Expose `APP_LOGS_DIR` (Path to `repo_root/data/logs`).
- Import paths from this module; avoid hard-coded filesystem strings.

Logging (minimal)
- Use a single helper that auto-initializes logging:
```python
from data_science_project.utils.logging import get_logger
logger = get_logger(__name__)
```
- Log at appropriate levels: debug/info/warning/error. 

Code generation expectations
- Small, focused modules; split when they grow.
- Prefer pure functions; separate I/O from computation.
- Write tests for new code (happy path + key edge cases).
- Avoid global state; pass dependencies explicitly; use dataclasses for simple configs.

Avoid
- Monolithic scripts, long functions/classes, implicit globals.
- Hard-coded paths; always use `data_science_project.config.paths`.
- Side effects at import; uncontrolled logging/printing.