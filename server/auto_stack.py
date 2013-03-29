import django

from photos.models import Photo, Stack

photos = Photo.objects.all()

for photo in photos:
    print photo.id

