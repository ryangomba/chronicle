from django.db import models
from entries.constants import BitKind
from django.contrib.auth.models import User
from chronicle import settings
from chronicle.helpers import timestamp_from_datetime
from photos.constants import PhotoStatus, StackStatus
import time
import json

class Stack(models.Model):
    id = models.CharField(max_length=40, primary_key=True, db_index=True)
    user = models.ForeignKey(User)
    timestamp = models.DateTimeField(db_index=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    status = models.IntegerField(default=StackStatus.ACTIVE, db_index=True)
    modified = models.BigIntegerField(blank=True, editable=False, db_index=True)
    cover_photo = models.ForeignKey('Photo', related_name='+', null=True)

    def __unicode__(self):
        return "Stack @ %s" % self.timestamp

    def to_dict(self, with_photos=False):
        dictionary = {
            "pk": self.id,
            "timestamp": timestamp_from_datetime(self.timestamp),
            "latitude": float(self.latitude) if self.latitude else None,
            "longitude": float(self.longitude) if self.longitude else None,
            "status": self.status,
        }
        if with_photos:
            photo_dicts = []
            for photo in self.photos.filter(category=0):
                photo_dict = photo.to_dict()
                photo_dicts.append(photo_dict)
            dictionary["photos"] = photo_dicts
        return dictionary

    def save(self, *args, **kwargs):
        self.modified = int(time.time() * 1000000)
        super(Stack, self).save(*args, **kwargs)


class Photo(models.Model):
    kind = BitKind.PHOTO

    id = models.CharField(max_length=40, primary_key=True, db_index=True)
    user = models.ForeignKey(User)
    timestamp = models.DateTimeField(db_index=True)
    filetype = models.CharField(max_length=16)
    aspect_ratio = models.FloatField()
    exif = models.TextField(null=True, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    stack = models.ForeignKey('Stack', related_name='photos')
    phash = models.CharField(max_length=16, db_index=True, blank=True, null=True)
    starred = models.BooleanField(default=False)
    edits = models.TextField(null=True, blank=True)

    # questionable if needed
    category = models.IntegerField(default=0, db_index=True)
    status = models.IntegerField(default=PhotoStatus.ACTIVE, db_index=True)
    modified = models.BigIntegerField(blank=True, editable=False, db_index=True)

    def __unicode__(self):
        return "Photo @ %s" % self.timestamp

    @property
    def original_url(self):
        return "%s/%s.%s" % (settings.STORAGE_BASE, self.id, self.filetype)
    
    @property
    def photo_url(self):
        return "%s/%s_1.jpg" % (settings.STORAGE_BASE, self.id)
 
    @property
    def edits_dict(self):
        return json.loads(self.edits) if self.edits else {}

    def update_edits(self, new_edits_dict, new_edits_timestamp):
        last_edit_ts = self.edits_dict.get("timestamp", 0)
        if new_edits_timestamp > last_edit_ts:
            new_edits_dict["timestamp"] = new_edits_timestamp
            self.edits = json.dumps(new_edits_dict)

    def to_dict(self):
        return {
            "type": self.kind,

            "pk": self.id,
            "timestamp": timestamp_from_datetime(self.timestamp),
            "filetype": self.filetype,
            "media_type": self.category,
            "url": self.photo_url,
            "aspect_ratio": self.aspect_ratio,
            "status": self.status,
            "latitude": float(self.latitude) if self.latitude else None,
            "longitude": float(self.longitude) if self.longitude else None,
            'starred': self.starred,
            'edits': self.edits,

            #"stack_id": self.stack_id,
            #"image_urls": {
            #    "original": self.original_url,
            #    "thumbnail": self.photo_url,
            #},
        }

    def save(self, *args, **kwargs):
        self.modified = int(time.time() * 1000000)

        # TEMP HACK
        self.stack.modified = self.modified
        self.stack.save()

        super(Photo, self).save(*args, **kwargs)

