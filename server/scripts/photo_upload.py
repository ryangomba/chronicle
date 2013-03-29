import os
import sys

import boto
from boto.s3.key import Key

BUCKET_NAME = "chronicle-storage"
AWS_KEY = "" # TODO: set securely
AWS_SECRET = "" # TODO: set securely

PHOTOS_PATH = sys.argv[1]

conn = boto.connect_s3(AWS_KEY, AWS_SECRET)
bucket = conn.get_bucket(BUCKET_NAME)

print "Starting photo upload..."

for path, dirs, filenames in os.walk(PHOTOS_PATH):
    for filename in filenames:
        if not filename.startswith("."):
            full_path = os.path.join(PHOTOS_PATH, path, filename)
            print filename

            aws_directory = "photos"

            k = Key(bucket)
            k.key = os.path.join(aws_directory, filename)
            k.set_contents_from_filename(full_path)
            k.make_public()

print "Finished photo upload"

