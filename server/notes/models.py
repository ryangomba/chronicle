from django.db import models
from entries.constants import BitKind
from django.contrib.auth.models import User

class Note(models.Model):
    kind = BitKind.NOTE

    user = models.ForeignKey(User)
    timestamp = models.DateTimeField()
    text = models.TextField()
    status = models.IntegerField(default=0)

    def __unicode__(self):
        return self.text[:100]

    def to_dict(self):
        return {
            "type": self.kind,

            "pk": self.id,
            "timestamp": self.timestamp.strftime('%s'),
            "text": self.text,
            "status": self.status,
        }

