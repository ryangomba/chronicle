# Local settings

DATABASES = {
    'default': {
        'ENGINE':   'django.db.backends.sqlite3',
        'NAME':     '/Users/Ryan/Dropbox/Projects/Chronicle/ChronicleServer/chronicle/db/chronicle.sqlite3',
        'USER':     '',
        'PASSWORD': '',
        'HOST':     '',
        'PORT':     '',
    }
}

STATIC_URL = "/static/"

STORAGE_BUCKET = "chronicle-scratch"
STORAGE_BASE = "http://chronicle-scratch.s3.amazonaws.com"

