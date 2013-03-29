import datetime

from tastypie import fields
from tastypie.resources import ModelResource
from tastypie.authorization import Authorization

from users.api.resources import UserResource
from notes.models import Note

class NoteResource(ModelResource):
    user = fields.ForeignKey(UserResource, 'user', full=True)

    class Meta:
        queryset = Note.objects.all()
        include_resource_uri = False
        resource_name = "notes"
        authorization= Authorization()

    def alter_deserialized_list_data(self, request, data):
        print 'dsfdsfsdfsdf'

    def alter_deserialized_detail_data(self, request, data):
        timestamp = data.get("timestamp")

        # TODO hacky; from backbone-forms
        if timestamp.endswith("Z"):
            timestamp = datetime.datetime.strptime(timestamp[:-1], '%Y-%m-%dT%H:%M:%S.%f')
            timestamp = timestamp + datetime.timedelta(hours=-7)
            data["timestamp"] = timestamp

        if request.method == "POST":
            data["user"] = {"id": 1}
            data["timestamp"] = data.get("timestamp", datetime.datetime.now())

        return data

