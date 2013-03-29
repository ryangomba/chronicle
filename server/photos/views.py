from django.shortcuts import render

#import pHash
from photos.models import Photo, Stack

def stacks(request):
    all_stacks = Stack.objects.order_by("timestamp")[:500]
    stacks = []
    last_photo = None
    for stack in all_stacks:
        stack.all_photos = stack.photos.order_by("timestamp")
        for photo in stack.all_photos:
            if last_photo:
                hash1 = int(last_photo.phash, 16)
                hash2 = int(photo.phash, 16)
                #hamming_distance = pHash.hamming_distance(hash1, hash2)
                time_delta = photo.timestamp - last_photo.timestamp
                photo.ham = hamming_distance
                photo.td = time_delta.total_seconds()
            else:
                photo.ham = 999
            last_photo = photo
        if len(stack.all_photos) > 0:
            stacks.append(stack)

    return render(request, 'photos/stacks.html', {
        'stacks': stacks,
    })

def dupes(request):
    photos = Photo.objects.all()[:1000]

    phashes = {}
    for photo in photos:
        if photo.phash:
            key = photo.phash + str(photo.timestamp)
            count = phashes.setdefault(key, [])
            phashes[key].append(photo)

    groups = []
    for group in phashes.values():
        if len(group) > 1:
            groups.append(group)

    return render(request, 'photos/dupes.html', {
        'groups': groups,
    })
    
