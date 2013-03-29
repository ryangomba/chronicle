from settings import *

# Production Settings

DATABASES = {
    'default': {
        'ENGINE':   'django.db.backends.postgresql_psycopg2',
        'NAME':     'chronicle',
        'USER':     'chronicle',
        'PASSWORD': '',
        'HOST':     '',
        'PORT':     '',
    }
}

INSTALLED_APPS += (
    'raven.contrib.django.raven_compat',
)

RAVEN_CONFIG = {
    'dsn': '',
}

STATIC_URL = "http://chronicle-static.s3.amazonaws.com/"

#STORAGE_BUCKET = "chronicle-storage"
#STORAGE_BASE = "http://chronicle-storage.s3.amazonaws.com"
STORAGE_BUCKET = "chronicle-scratch"
STORAGE_BASE = "http://chronicle-scratch.s3.amazonaws.com"

