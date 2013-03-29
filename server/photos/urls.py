from django.conf.urls import patterns, url

urlpatterns = patterns('',
    url(r'^stacks/$', "photos.views.stacks"),
    url(r'^dupes/$', "photos.views.dupes"),
)

