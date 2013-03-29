from django.db import models
from entries.constants import BitKind
from django.contrib.auth.models import User

class Venue(models.Model):
    name = models.CharField(max_length=200)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)

    def __unicode__(self):
        return "%s" % self.name

    def to_dict(self):
        return {
            "pk": self.id,
            "name": self.name,
            "lat": str(self.latitude),
            "lon": str(self.longitude),
        }


class Location(models.Model):
    kind = BitKind.VISIT

    user = models.ForeignKey(User)
    venue = models.ForeignKey(Venue)
    timestamp = models.DateTimeField()
    status = models.IntegerField(default=0)

    def __unicode__(self):
        return "%s @ %s" % (self.venue.name, self.timestamp)

    @property
    def time_string(self):
        time_tuple = self.timestamp.timetuple()
        hour = time_tuple.tm_hour
        hour = hour if hour <= 12 else hour - 12
        minute = time_tuple.tm_min
        minute = minute / 5 * 5
        return "%d:%02d" % (hour, minute)

    def to_dict(self):
        return {
            "type": self.kind,

            "pk": self.id,
            "timestamp": self.timestamp.strftime('%s'),
            "time": self.time_string,
            "status": self.status,

            "venue": self.venue.to_dict(),
        }

