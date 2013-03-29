from django.conf.urls import patterns, include, url
from django.contrib import admin
admin.autodiscover()

from django.contrib.staticfiles.urls import staticfiles_urlpatterns

from tastypie.api import Api
from users.api.resources import UserResource
from notes.api.resources import NoteResource
from photos.api.resources import PhotoResource
from locations.api.resources import VisitResource, VenueResource
from data.api.resources import DataPointResource, DataSetResource

api_v1 = Api(api_name='v1')
api_v1.register(NoteResource())
api_v1.register(PhotoResource())
api_v1.register(VisitResource())
api_v1.register(VenueResource())
api_v1.register(DataPointResource())
api_v1.register(DataSetResource())

urlpatterns = patterns('',
    # admin
    url(r'^admin/', include(admin.site.urls)),

    # home
    url(r'^(\d+)/$', 'entries.views.home'),

    # photos
    url(r'^photos/', include('photos.urls')),

    # uploads
    url(r'^uploads/', include('uploads.urls')),

    # api
    url(r'^api/users/', include('users.api.urls')),
    url(r'^api/entries/', include('entries.api.urls')),
    url(r'^api/photos/', include('photos.api.urls')),
    url(r'^api/notes/', include('notes.api.urls')),
    url(r'^api/uploads/', include('uploads.api.urls')),

    # api resources
    url(r'^api/', include(api_v1.urls)),
)

