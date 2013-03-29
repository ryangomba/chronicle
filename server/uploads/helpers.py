import uuid
import time
import datetime
from PIL import Image
import StringIO
from django.core.files.base import ContentFile
import boto
from boto.s3.key import Key
import json
#import pHash
from tempfile import NamedTemporaryFile

from chronicle import settings

from uploads import file_helper, exif_helper, image_helper
from uploads.exceptions import FileAlreadyUploaded
from photos.models import Photo, Stack
from photos.constants import PhotoCategory

PHOTO_EXTENSIONS = ["jpg", "jpeg", "png"]
AUDIO_EXTENSIONS = ["mp3", "aac"]
VIDEO_EXTENSIONS = ["mov", "m4v"]
TEXT_EXTENSIONS =  ["txt", "text", "md", "markdown"]

THUMBNAIL_MIN_EDGE_SIZE = 1136

def upload_file(f):
    extension = f.name.rpartition(".")[2].lower()
    if extension in PHOTO_EXTENSIONS:
        return handle_photo(f, extension)
    if extension in AUDIO_EXTENSIONS:
        return handle_audio(f, extension)
    if extension in VIDEO_EXTENSIONS:
        return handle_video(f, extension)
    if extension in TEXT_EXTENSIONS:
        return handle_text(f, extension)
    return handle_file(f, extension)

def upload_photo(user_id, f, pk, filetype, created):
    return handle_photo(user_id, f, pk, filetype, created)

def upload_file_to_s3(f, key, bucket_name=None):
    if not settings.PROD:
        local_url = "/Users/Ryan/Dropbox/Projects/Chronicle/ChronicleServer/storage/" + key
        with open(local_url, 'w+') as f_out:
            f_out.write(f.read())
        time.sleep(1)
        return

    conn = boto.connect_s3(settings.AWS_KEY, settings.AWS_SECRET)
    if not bucket_name:
        bucket_name = settings.STORAGE_BUCKET
    bucket = conn.get_bucket(bucket_name)
    k = Key(bucket)
    k.key = key
    k.set_contents_from_file(f)
    k.make_public()

def handle_file(f, extension):
    return

def handle_text(text_file, extension):
    return

def handle_audio(audio_file, extension):
    return

def handle_video(video_file, extension):
    # upload the video
    upload_file_to_s3(video_file, PHOTOS_DIRECTORY + thumbnail_name)
    return

def handle_photo(user_id, image_file, pk, filetype, created):
    client_md5, client_user_id = pk.split("_")

    # validate the given user_id
    if client_user_id != str(user_id):
        raise Exception("client provided user_id is incorrect")

    # open the image
    original_image = Image.open(image_file)

    # validate the given md5 hash
    md5 = file_helper.md5_for_file(image_file)
    if md5 != client_md5:
        raise Exception("pk and md5 do not match")

    # check for a dupe
    existing_results = Photo.objects.filter(user_id=user_id, id=pk)
    if existing_results:
        return existing_results[0]

    # get the exif info
    exif_json = None
    exif_info = exif_helper.exif_info_for_image(original_image)
    if exif_info:
        exif_info.pop(37500, None)
        exif_json = json.dumps(exif_info)
    exif_dict = exif_helper.exif_dict_for_image(original_image)

    """
    # calculate the phash
    with NamedTemporaryFile() as temp_file:
        image_file.seek(0)
        image_data = image_file.read()
        temp_file.write(image_data)
        phash_value = pHash.imagehash(temp_file.name)
        phash = "%016x" % phash_value
        temp_file.close()
    """

    # determine the thumbnail size
    width, height = original_image.size
    ratio = max(width, height) / float(min(width, height))
    max_size = int(THUMBNAIL_MIN_EDGE_SIZE * ratio)
    thumbnail_size = (max_size, max_size)

    # generate the other images
    rotated_image = image_helper.rotated_image(original_image, exif_dict)
    thumbnail = image_helper.thumbnail_of_size(rotated_image, thumbnail_size)
    thumbnail_io = StringIO.StringIO()
    thumbnail.save(thumbnail_io, format="JPEG", quality=95)
    thumbnail_file = ContentFile(thumbnail_io.getvalue())

    # get image info
    timestamp = exif_helper.datetime_from_exif_dict(exif_dict) or created
    width, height = rotated_image.size
    aspect_ratio = float(width) / float(height)
    dimensions = (width, height)

    # generate the names
    image_name = "originals/%s.%s" % (pk, filetype)
    thumbnail_name = "small/%s.jpg" % pk

    # reset the file
    image_file.seek(0)

    # upload the images
    upload_file_to_s3(thumbnail_file, thumbnail_name)
    upload_file_to_s3(image_file, image_name)
    
    # get the coordinates
    coordinates = exif_helper.coordinates_from_exif_dict(exif_dict)
    lat, lon = coordinates or (None, None)

    # define the category
    screenshot_sizes = (
        (320, 480),
        (480, 320),
        (640, 960),
        (960, 640),

        (640, 1136),
        (1136, 640),

        (768, 1024),
        (1024, 768),
        (1536, 2048),
        (2048, 1536),
    )
    is_screenshot = dimensions in screenshot_sizes
    category = PhotoCategory.SCREENSHOT if is_screenshot else PhotoCategory.PHOTO

    # save to the db
    photo = Photo(
        id = pk,
        user_id = user_id,
        timestamp = timestamp,
        filetype = filetype,
        category = category,
        aspect_ratio = aspect_ratio,
        latitude = lat,
        longitude = lon,
        exif = exif_json,
        #phash = phash,
    )
    stack = Stack(
        id = photo.id,
        user_id = photo.user_id,
        timestamp = photo.timestamp,
    )
    photo.stack = stack
    stack.save()
    photo.save()

    return photo

