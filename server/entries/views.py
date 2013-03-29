from django.shortcuts import render

def home(request, user_id):
    return render(request, 'entries/index.html', {
        'user_id': user_id,
    })

