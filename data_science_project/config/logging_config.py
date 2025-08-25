from data_science_project.config.paths import APP_LOGS_DIR

LOGGING_CONFIG = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'standard': {
            'format': '%(asctime)s [%(levelname)s] %(name)s: %(message)s'
        },
    },
    'handlers': {
        'default': {
            'level': 'INFO',
            'formatter': 'standard',
            'class': 'logging.StreamHandler',
            'stream': 'ext://sys.stdout',
        },
        'file_handler': {
            'level': 'INFO',
            'formatter': 'standard',
            'class': 'logging.FileHandler',
            'filename': str(APP_LOGS_DIR / 'app.log'),
            'mode': 'a',
        },
        'model_file_handler': {
            'level': 'INFO',
            'formatter': 'standard',
            'class': 'logging.FileHandler',
            'filename': str(APP_LOGS_DIR / 'model_handler.log'),
            'mode': 'a',
        },
    },
    'loggers': {
        '': {  # root logger
            'handlers': ['default', 'file_handler'],
            'level': 'INFO',
            'propagate': True
        },
        'model_handler': {
            'handlers': ['default', 'model_file_handler'],
            'level': 'DEBUG',
            'propagate': False
        },
    }
}