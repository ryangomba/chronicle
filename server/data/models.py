from django.db import models
from entries.constants import BitKind
from django.contrib.auth.models import User

class DataSet(models.Model):
    user = models.ForeignKey(User)
    name = models.CharField(max_length=100)

    def __unicode__(self):
        return self.name

    def to_dict(self):
        return {
            "pk": self.id,
            "name": self.name,
        }


class DataPoint(models.Model):
    kind = BitKind.DATA

    user = models.ForeignKey(User)
    dataset = models.ForeignKey(DataSet)
    timestamp = models.DateTimeField()
    value = models.FloatField()
    status = models.IntegerField(default=0)

    def __unicode__(self):
        return "%s %s" % (self.value, self.dataset)

    def to_dict(self):
        return {
            "type": self.kind,

            "pk": self.id,
            "timestamp": self.timestamp.strftime('%s'),
            "value": self.value,
            "status": self.status,

            "set": self.dataset.to_dict(),
        }

