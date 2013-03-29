from tastypie.resources import ModelResource
from tastypie.authorization import Authorization
from data.models import DataPoint, DataSet

class DataPointResource(ModelResource):
    class Meta:
        queryset = DataPoint.objects.all()
        include_resource_uri = False
        resource_name = "datapoints"
        authorization= Authorization()

class DataSetResource(ModelResource):
    class Meta:
        queryset = DataSet.objects.all()
        include_resource_uri = False
        resource_name = "datasets"
        authorization= Authorization()

