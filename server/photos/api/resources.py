from tastypie.resources import ModelResource
from tastypie.authorization import Authorization
from photos.models import Photo

class PhotoResource(ModelResource):
    class Meta:
        queryset = Photo.objects.all()
        include_resource_uri = False
        resource_name = "photos"
        authorization= Authorization()

