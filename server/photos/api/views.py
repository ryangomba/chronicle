from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
import json

from photos.models import Photo, Stack
from photos.constants import PhotoStatus

@login_required
def sync(request):
    cursor = int(request.GET.get("cursor", 0))
    limit = 100

    photos_query = Photo.objects.filter(
        user_id = request.user.id,
        modified__gt = cursor
    )
    photos_count = photos_query.count()
    photos_queryset = photos_query.order_by('modified')[:limit]
    photos = list(photos_queryset)

    photo_dicts = [p.to_dict() for p in photos]

    new_cursor = photos[-1].modified if photos else cursor
    more_available = max(photos_count - limit, 0)

    return HttpResponse(json.dumps({
        'cursor': new_cursor,
        'photos': photo_dicts,
        'more_available': more_available,
    }), mimetype="application/json")

@csrf_exempt
@login_required
def update(request, photo_id):
    photo = Photo.objects.get(id=photo_id)

    timestamp = request.POST["timestamp"]

    status_value = request.POST.get("status")
    if status_value is not None:
        status = int(status_value)
        if status in (PhotoStatus.HIDDEN, PhotoStatus.ACTIVE):
            photo.status = status

    starred_value = request.POST.get("starred")
    if starred_value is not None:
        starred = bool(int(starred_value))
        photo.starred = starred

    edits_value = request.POST.get("edits")
    if edits_value is not None:
        new_edits_dict = json.loads(edits_value)
        photo.update_edits(new_edits_dict, timestamp)

    photo.save()

    return HttpResponse(json.dumps({
        "photo": photo.to_dict(),
    }), mimetype="application/json")

