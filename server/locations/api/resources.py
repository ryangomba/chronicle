from tastypie.resources import ModelResource
from tastypie.authorization import Authorization
from locations.models import Location, Venue

class VisitResource(ModelResource):
    class Meta:
        queryset = Location.objects.all()
        include_resource_uri = False
        resource_name = "visits"
        authorization= Authorization()

class VenueResource(ModelResource):
    class Meta:
        queryset = Venue.objects.all()
        include_resource_uri = False
        resource_name = "venues"
        authorization= Authorization()

