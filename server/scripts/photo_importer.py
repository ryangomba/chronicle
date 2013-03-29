import os
from datetime import datetime
from datetime import timedelta
import uuid
import time
from PIL import Image
import sys
import shutil

PHOTOS_PATH = sys.argv[1]

OUTPUT_DIR = os.path.join(PHOTOS_PATH, "__out")
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

OUTPUT_PATH = os.path.join(PHOTOS_PATH, "__out.txt")

def int_from_string(string):
    try:
        return int(string)
    except:
        return 0

def datetime_from_date_string(date_string):
    date_string = date_string.replace(".", ":")
    date_string = date_string.replace(" ", ":")
    comps = date_string.split(":")
    comps = [int_from_string(comp) for comp in comps]
    if comps[2] > 31:
        comps.insert(0, comps.pop(2))
    if len(comps) == 3:
        comps += [0, 0, 0]
    if sum(comps) == 0:
        return None
    try:
        dt = datetime(*comps)
    except:
        print "ERROR", comps
        exit();
    return dt

def timestamp_for_image(image, image_path):
    try:
        exif_data = image._getexif()
    except:
        exif_data = None
    
    if exif_data is None:
        timestamp = os.path.getctime(image_path)
        return datetime.fromtimestamp(timestamp)

    date_string = exif_data.get(36867)

    if date_string is None:
        geo_data = exif_data.get(34853)
        if geo_data:
            date_string = geo_data.get(29)

    if date_string:
        dt = datetime_from_date_string(date_string)
        if dt:
            return dt

    timestamp = os.path.getctime(image_path)
    return datetime.fromtimestamp(timestamp)

def rotated_image(image):
    try:
        exifdict = image._getexif()
    except:
        exifdict = None
    if exifdict:
        orientation = exifdict.get(274)
        if orientation == 6:
            image = image.rotate(-90)
    return image

with open(OUTPUT_PATH, "a+") as output_f:
    for path, dirs, files in os.walk(PHOTOS_PATH):
        for f in files:
            if "__out" in path or f.startswith(".") or f.startswith("_") or "." not in f:
                continue
            image_path = os.path.join(path, f)
            print image_path
            original_image = Image.open(image_path)
            image = rotated_image(original_image)
            image_hash = uuid.uuid1().hex
            image_name = image_hash + "." + image_path.rpartition(".")[2]

            # sql
            timestamp = timestamp_for_image(original_image, image_path) + timedelta(hours=5)
            width, height = image.size
            sql = "INSERT INTO \"photos_photo\" VALUES (DEFAULT, 1, '%s', '%s', %s, %s, 0);" % (
                timestamp, image_name, width, height,
            )
            print sql
            output_f.write("%s\n" % sql)

            # copy the original
            new_image_path = os.path.join(OUTPUT_DIR, image_name)
            shutil.copy2(image_path, new_image_path)

            # generate and save the thumbnail
            thumbnail_size = (580, 870)
            image.thumbnail(thumbnail_size, Image.ANTIALIAS)
            thumbnail_name = image_hash + "_1.jpg"
            thumbnail_path = os.path.join(OUTPUT_DIR, thumbnail_name)
            image.save(thumbnail_path, "JPEG")

            # rename the original so we know it has been processed
            os.rename(image_path, os.path.join(path, "_" + f))

