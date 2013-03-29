import os
import sys

sys.path.append('/home/ec2-user/ChronicleServer')
os.environ['DJANGO_SETTINGS_MODULE'] = 'chronicle.settings'
from django.core.management import setup_environ
from chronicle import settings
setup_environ(settings)

import StringIO
import urllib2
from PIL import Image
import json

from photos.models import Photo
from uploads import exif_helper

start = sys.argv[1]
photos = Photo.objects.filter(id__gt=start).order_by("id")

def clean_exif_info(exif_info):
    exif_info.pop(37500, None)
    for k, v in exif_info.items():
        if type(v) == str:
            try:
                v.encode('utf-8')
            except UnicodeDecodeError:
                del exif_info[k]
    return exif_info

i = len(photos)
for photo in photos:
    original_image_url = photo.original_url
    original_image_data = urllib2.urlopen(original_image_url).read()
    original_image = Image.open(StringIO.StringIO(original_image_data))

    # get the exif info
    exif_info = exif_helper.exif_info_for_image(original_image)

    if exif_info:
        exif_info = clean_exif_info(exif_info)
        exif_json = json.dumps(exif_info)
        photo.exif = exif_json

    # get the exif info
    exif_dict = exif_helper.exif_dict_for_image(original_image)

    # get the coordinates
    coordinates = exif_helper.coordinates_from_exif_dict(exif_dict)
    lat, lon = coordinates or (None, None)

    if lat and lon:
        photo.latitude = lat
        photo.longitude = lon

    photo.save()

    i -= 1
    print i, photo.id, lat, lon

