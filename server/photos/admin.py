from django.contrib import admin
from photos.models import Photo, Stack

class PhotoAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'timestamp', 'filetype', 'status', 'modified',)
    list_filter = ('user',)

admin.site.register(Photo, PhotoAdmin)
admin.site.register(Stack)

