from logging.config import dictConfig
import logging
from pathlib import Path

from data_science_project.config.logging_config import LOGGING_CONFIG
from data_science_project.config.paths import APP_LOGS_DIR

_CONFIGURED = False

def get_logger(name: str) -> logging.Logger:
    """
    Get a configured logger by name.
    Usage:  from data_science_project.utils.logging import get_logger
            logger = get_logger(__name__)
    """

    global _CONFIGURED
    if not _CONFIGURED:
        Path(APP_LOGS_DIR).mkdir(parents=True, exist_ok=True)
        dictConfig(LOGGING_CONFIG)
        _CONFIGURED = True
    return logging.getLogger(name)