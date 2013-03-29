import datetime as dt

from django.db import models
from django.contrib.auth.models import User

from entries import helpers as entry_helper

class Entry(models.Model):
    class Meta:
        verbose_name_plural = "entries"

    user = models.ForeignKey(User)
    day = models.IntegerField(unique=True)
    name = models.CharField(max_length=100, null=True, blank=True)
    bit_list = models.TextField(default="", blank=True)
    noteworthy = models.IntegerField(default=0)

    @property
    def date(self):
        return entry_helper.datetime_range_for_day(self.day)[0]

    @property
    def day_string(self):
        return self.date.strftime("%A")

    @property
    def date_string(self):
        return self.date.strftime("%B %-d")

    @property
    def title(self):
        if self.name:
            return self.name
        return self.date_string

    @property
    def subtitle(self):
        if self.name:
            return "%s, %s" % (self.day_string, self.date_string)
        return self.day_string

    def __unicode__(self):
        description = "Day %s" % self.day
        if self.name:
            description += ": %s" % self.name
        return description

    def to_dict(self):
        return {
            "pk": self.id,
            "day": self.day,
            "title": self.title,
            "subtitle": self.subtitle,
            "noteworthy": self.noteworthy,
            "bit_list": self.bit_list,
        }

