from django.conf.urls import patterns, url

urlpatterns = patterns('',
    url(r'^$', 'uploads.api.views.upload'),
    url(r'^photo/$', 'uploads.api.views.upload_photo'),
)

