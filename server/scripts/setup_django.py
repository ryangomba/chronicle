import os
import sys

sys.path.append('/home/ec2-user/ChronicleServer')
os.environ['DJANGO_SETTINGS_MODULE'] = 'chronicle.settings'
from django.core.management import setup_environ
from chronicle import settings
setup_environ(settings)

