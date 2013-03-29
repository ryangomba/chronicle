import json
from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt

@csrf_exempt
def create(request):
    note = Note.create(request.POST)
    print note.id

    return HttpResponse(json.dumps({
        "note": note.to_dict,
    }), mimetype="application/json")

