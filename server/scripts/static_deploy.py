import os
import sys

import boto
from boto.s3.key import Key

BUCKET_NAME = "chronicle-static"
AWS_KEY = "" # TODO: set securely
AWS_SECRET = "" # TODO: set securely

SCRIPT_PATH = os.path.realpath(__file__)
APP_PATH = SCRIPT_PATH.rpartition("/scripts")[0]
STATIC_PATH = os.path.join(APP_PATH, "static")

conn = boto.connect_s3(AWS_KEY, AWS_SECRET)
bucket = conn.get_bucket(BUCKET_NAME)

print "Starting static deploy..."

for path, dirs, filenames in os.walk(STATIC_PATH):
    for filename in filenames:
        if not filename.startswith("."):
            full_path = os.path.join(STATIC_PATH, path, filename)
            relative_path = full_path.rpartition("static/")[2]
            print relative_path

            aws_directory, _s, aws_filename = relative_path.rpartition("/")

            k = Key(bucket)
            k.key = os.path.join(aws_directory, aws_filename)
            k.set_contents_from_filename(full_path)
            k.make_public()

print "Finished static deploy"

