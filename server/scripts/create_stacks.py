import os
import sys

sys.path.append('/home/ec2-user/ChronicleServer')
os.environ['DJANGO_SETTINGS_MODULE'] = 'chronicle.settings'
from django.core.management import setup_environ
from chronicle import settings
setup_environ(settings)

from photos.models import Photo, Stack

def create_stacks():
    for photo in photos:
        stack = Stack(
            id = photo.id,
            user_id = photo.user_id,
            timestamp = photo.timestamp,
        )
        stack.save()

def set_stack_for_photos():
    for i, photo in enumerate(photos):
        if not photo.stack_id:
            photo.stack_id = photo.id
            photo.save()
        print i

def copy_coordinates():
    for i, photo in enumerate(photos):
        stack = photo.stack
        stack.latitude = photo.latitude
        stack.longitude = photo.longitude
        stack.save()
        print i

photos = Photo.objects.all()
copy_coordinates()

