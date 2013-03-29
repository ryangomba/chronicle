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
import boto
from boto.s3.key import Key
from django.core.files.base import ContentFile

from chronicle import settings
from photos.models import Photo
from uploads import exif_helper, image_helper

def make_key_public(bucket_name, key):
    conn = boto.connect_s3(settings.AWS_KEY, settings.AWS_SECRET)
    bucket = conn.get_bucket(bucket_name)
    k = Key(bucket)
    k.key = key
    k.make_public()

def lowercase():
    conn = boto.connect_s3(settings.AWS_KEY, settings.AWS_SECRET)
    bucket = conn.get_bucket(settings.STORAGE_BUCKET)
    keys = bucket.list()
    i = 0
    for key in keys:
        extension = key.key.rpartition(".")[2]
        if extension != extension.lower():
            i += 1
    for key in keys:
        extension = key.key.rpartition(".")[2]
        if extension != extension.lower():
            new_key_name = key.key.lower()
            new_key = key.copy(settings.STORAGE_BUCKET, new_key_name, preserve_acl=True)
            if new_key.exists:
                key.delete()
            i -= 1
            print i, new_key.key
    exit()

def upload_file_to_s3(f, key, bucket_name=None, attempt=1):
    try:
        conn = boto.connect_s3(settings.AWS_KEY, settings.AWS_SECRET)
        if not bucket_name:
            bucket_name = settings.STORAGE_BUCKET
        bucket = conn.get_bucket(bucket_name)
        k = Key(bucket)
        k.key = key
        f.seek(0)
        k.set_contents_from_file(f)
        k.make_public()
    except Exception as e:
        print e
        if attempt <= 20:
            print "Trying again..."
            upload_file_to_s3(f, key, bucket_name=bucket_name, attempt=attempt+1)
        else:
            raise e

def image_at_url(url, attempt=1):
    try:
        original_image_data = urllib2.urlopen(original_image_url).read()
        return Image.open(StringIO.StringIO(original_image_data))
    except Exception as e:
        print e
        if attempt <= 20:
            print "Trying again..."
            return image_at_url(url, attempt=attempt+1)
        else:
            raise e

start = sys.argv[1]
photos = Photo.objects.filter(id__gt=start).order_by("id")

i = len(photos)
for photo in photos:
    original_image_url = photo.original_url

    # ensure the key is public
    #key = original_image_url.rpartition("/")[2]
    #make_key_public(settings.STORAGE_BUCKET, key)

    # open the image
    original_image = image_at_url(original_image_url)

    # get the exif info
    exif_dict = exif_helper.exif_dict_for_image(original_image)

    # determine the size
    width, height = original_image.size
    ratio = max(width, height) / float(min(width, height))
    max_size = 640 * ratio
    thumbnail_size = (max_size, max_size)

    # generate the other images
    rotated_image = image_helper.rotated_image(original_image, exif_dict)
    thumbnail = image_helper.thumbnail_of_size(rotated_image, thumbnail_size)
    thumbnail_io = StringIO.StringIO()
    thumbnail.save(thumbnail_io, format="JPEG", quality=90)
    thumbnail_file = ContentFile(thumbnail_io.getvalue())

    key = "%s_3.jpg" % photo.id
    upload_file_to_s3(thumbnail_file, key)
    i -= 1
    print i, key

