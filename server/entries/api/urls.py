from django.conf.urls import patterns, url

urlpatterns = patterns('',
    url(r'^$', "entries.api.views.get_all_entries"),
    url(r'^(\d+)/$', "entries.api.views.entry"),
)

