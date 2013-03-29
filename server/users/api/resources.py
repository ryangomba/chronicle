from tastypie.resources import ModelResource
from tastypie.authorization import Authorization
from django.contrib.auth.models import User

class UserResource(ModelResource):
    class Meta:
        queryset = User.objects.all()
        include_resource_uri = False
        resource_name = "users"
        authorization= Authorization()
        excludes = [
            "is_active",
            "is_staff",
            "is_superuser",
            "date_joined",
            "email",
            "last_login",
            "password",
        ]

