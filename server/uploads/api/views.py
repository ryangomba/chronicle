from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
import json

from chronicle.helpers import datetime_from_timestamp
from uploads import helpers as upload_helper
from uploads.exceptions import FileAlreadyUploaded

@csrf_exempt
@login_required
def upload(request):
    f = request.FILES["file"]

    try:
        upload_helper.upload_file(f)
    except FileAlreadyUploaded:
        return HttpResponse("File already uploaded", status=400)

    return HttpResponse(status=201)

@csrf_exempt
@login_required
def upload_photo(request):
    pk = request.POST["pk"]
    filetype = request.POST["filetype"].lower()
    created_ts = float(request.POST["created"])
    created_dt = datetime_from_timestamp(created_ts)

    f = request.FILES["file"]

    photo = upload_helper.upload_photo(request.user.id, f, pk, filetype, created_dt)
    return HttpResponse(json.dumps(photo.to_dict()), mimetype="application/json")

