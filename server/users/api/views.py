from django.views.decorators.http import require_POST
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required

from django.contrib.auth import authenticate
from django.contrib.auth import login as django_login
from django.contrib.auth import logout as django_logout

from chronicle.helpers import json_response, json_error

from django.contrib.auth.models import User

@require_POST
@csrf_exempt
def register(request):
    post_dict = request.POST
    username = post_dict.get('username', '').strip()
    password = post_dict.get('password', '').strip()

    if not username:
        return json_error(400, 'Username required')

    if not password:
        return json_error(400, 'Password required')

    if User.objects.filter(username = username).exists():
        return json_error(400, 'A user with that username already exists')

    user = User(username = username)
    user.set_password(password)
    user.save()

    user = authenticate(
        username = username,
        password = password
    )

    django_login(request, user)

    return json_response({
        'user': {
            'pk': user.id,
        },
    })

@require_POST
@csrf_exempt
def login(request):
    post_dict = request.POST
    username = post_dict.get('username', '').strip()
    password = post_dict.get('password', '').strip()

    if not username:
        return json_error(400, 'Username required')

    if not password:
        return json_error(400, 'Password required')

    user = authenticate(
        username = username,
        password = password
    )

    if not user:
        return json_error(400, 'Incorrect username or password')

    django_login(request, user)

    return json_response({
        'user': {
            'pk': user.id,
        },
    })

@require_POST
@csrf_exempt
@login_required
def logout(request):
    django_logout(request)
    return json_response({})


