from django.conf.urls import patterns, url

urlpatterns = patterns('',
    url(r'^sync/$', 'photos.api.views.sync'),
    url(r'^(\w+)/$', 'photos.api.views.update'),
)

