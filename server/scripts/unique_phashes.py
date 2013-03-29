import setup_django

import json

from photos.models import Photo, Stack
from uploads import file_helper

def exif_hash(photo):
    if photo.exif:
        return file_helper.md5_for_string(photo.exif)
    return ''

def unique_key(photo):
    return "%d%s%s%s" % (
        photo.user_id,
        photo.timestamp.strftime("%s"),
        photo.phash or "",
        exif_hash(photo),
    )

photos = Photo.objects.filter(filetype="jpg")

phashes = {}
for photo in photos:
    key = unique_key(photo)
    count = phashes.setdefault(key, [])
    phashes[key].append(photo)

num_collisions = 0
for phash, photos in phashes.items():
    if len(photos) > 1:
        #print [photo.id for photo in photos]
        num_collisions += 1

print num_collisions, "collisions"

