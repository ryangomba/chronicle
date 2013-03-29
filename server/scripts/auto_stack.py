import setup_django

from chronicle import settings

import sys
import pHash
import StringIO
import urllib2
import boto
from boto.s3.key import Key
from PIL import Image
from tempfile import NamedTemporaryFile

from photos.models import Photo, Stack
from uploads import exif_helper, image_helper

def categorize_photos(photos):
    for i, photo in enumerate(photos):
        if photo.filetype == "png":
            photo.category = 1
            photo.save()
            print i

def make_square_image(image):
    width, height = image.size
    if width == height:
        return image

    if width > height:
        delta = width - height
        left = int(delta / 2)
        upper = 0
        right = height + left
        lower = height
    else:
        delta = height - width
        left = 0
        upper = int(delta / 2)
        right = width
        lower = width + upper

    image = image.crop((left, upper, right, lower))
    return image

def image_at_url(url, attempt=1):
    try:
        original_image_data = urllib2.urlopen(url).read()
        return Image.open(StringIO.StringIO(original_image_data))
    except Exception as e:
        print e
        if attempt <= 20:
            print "Trying again..."
            return image_at_url(url, attempt=attempt+1)
        else:
            raise e

def make_thumbnail(image_url):
    # open the image
    original_image = image_at_url(image_url)

    # get the exif info
    exif_dict = exif_helper.exif_dict_for_image(original_image)

    # generate the other images
    rotated_image = image_helper.rotated_image(original_image, exif_dict)
    square_image = make_square_image(rotated_image)
    thumbnail = image_helper.thumbnail_of_size(square_image, (480, 480))
    return thumbnail

def upload_file_to_s3(f):
    conn = boto.connect_s3(settings.AWS_KEY, settings.AWS_SECRET)
    bucket_name = "chronicle-scratch"
    bucket = conn.get_bucket(bucket_name)
    k = Key(bucket)
    k.key = "tmp.jpg"
    k.set_contents_from_file(f)
    k.make_public()

def generate_hashes(photos):
    i = len(photos)
    for photo in photos:
        if not photo.phash:
            original_image_url = photo.original_url
            thumbnail = make_thumbnail(original_image_url)

            thumbnail_io = StringIO.StringIO()
            thumbnail.save(thumbnail_io, format="JPEG", quality=90)

            phash = None
            with NamedTemporaryFile() as f:
                f.write(thumbnail_io.getvalue())
                f.seek(0)
                #upload_file_to_s3(f)
                phash = pHash.imagehash(f.name)
                f.close()
                #exit()

            if phash:
                phash_str = "%016x" % phash
                photo.phash = phash_str
                photo.save()
            else:
                print "error saving phash"
            i -= 1
            print i, photo.id, phash

def reset_stack_for_photos(photos):
    count = len(photos)
    for i, photo in enumerate(photos):
        if photo.stack_id != photo.id:
            photo.stack_id = photo.id
            photo.save()
        print count - i

def auto_stack_photos(photos):
    for i in range(1, len(photos) - 1):
        last_photo = photos[i-1]
        this_photo = photos[i]
        time_delta = this_photo.timestamp - last_photo.timestamp
        time_delta_secs = time_delta.total_seconds()
        extra_hams = (60 - time_delta_secs) / 6.0
        extra_hams = 0
        hash1 = int(last_photo.phash, 16)
        hash2 = int(this_photo.phash, 16)
        hamming_distance = pHash.hamming_distance(hash1, hash2)
        if hamming_distance <= (22 + extra_hams) and time_delta_secs < 300:
        #if delta_secs <= 2.0 and last_photo.exif and this_photo.exif:
            this_photo.stack_id = last_photo.stack_id
            this_photo.save()
        print i, time_delta_secs, hamming_distance

def dedupe(photos):
    c = 0
    for i in range(1, len(photos) - 1):
        last_photo = photos[i-1]
        this_photo = photos[i]
        time_delta = this_photo.timestamp - last_photo.timestamp
        time_delta_secs = time_delta.total_seconds()
        hash1 = int(last_photo.phash, 16)
        hash2 = int(this_photo.phash, 16)
        hamming_distance = pHash.hamming_distance(hash1, hash2)
        if hamming_distance == 0 and time_delta_secs == 0:
            if last_photo.exif == this_photo.exif:
                this_photo.status = 2
                this_photo.save()
                this_stack = Stack.objects.get(id=this_photo.id)
                this_stack.status = 2
                this_stack.save()
                c += 1
                print c, this_photo.id, last_photo.id, "Dupe!"
            #this_photo.stack_id = last_photo.stack_id
            #this_photo.save()
        #print i, time_delta_secs, hamming_distance


#start = sys.argv[1]
#photos = Photo.objects.filter(category=0, id__gt=start).order_by("id")
#generate_hashes(photos)
#exit()

photos = Photo.objects.filter(status=0, category=0).order_by("timestamp")
reset_stack_for_photos(photos)
auto_stack_photos(photos)
#dedupe(photos)

