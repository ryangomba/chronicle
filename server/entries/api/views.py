import json
import datetime as dt
from itertools import chain

from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt
from chronicle.helpers import chronicle_response

from entries.models import Entry
from photos.models import Photo
from notes.models import Note
from data.models import DataPoint
from locations.models import Location
from entries import helpers as entry_helper

DAYS_TO_FETCH = 7

def get_all_entries(request):
    user_id = 1

    end_datetime = dt.datetime.utcnow()
    start_datetime = end_datetime - dt.timedelta(days=DAYS_TO_FETCH)
    timestamp_range = (start_datetime, end_datetime)

    start_day = entry_helper.day_for_datetime(start_datetime)
    end_day = entry_helper.day_for_datetime(end_datetime)
    day_range = (start_day, end_day)

    entries = Entry.objects.filter(user_id=user_id, day__range=day_range)
    entries = list(entries)
    entries = {e.day: e for e in entries}

    #photos = []
    photos = Photo.objects.filter(user_id=user_id, status=0, timestamp__range=timestamp_range)
    notes = Note.objects.filter(user_id=user_id, status=0, timestamp__range=timestamp_range)
    data_points = DataPoint.objects.filter(user_id=user_id, status=0, timestamp__range=timestamp_range)
    locations = Location.objects.filter(user_id=user_id, status=0, timestamp__range=timestamp_range)
    all_bits = list(chain(photos, notes, locations, data_points))
    all_bits.sort(key=lambda b: b.timestamp)

    entry_dicts = []
    for day in range(*day_range):
        entry = entries.get(day, Entry(user_id=user_id, day=day))
        start, end = entry_helper.datetime_range_for_day(day)
        bits = [b for b in all_bits if b.timestamp >= start and b.timestamp < end]
        bits = entry_helper.ordered_bits_from_string(bits, entry.bit_list)

        entry_dict = entry.to_dict()
        bit_dicts = [bit.to_dict() for bit in bits]
        entry_dict["bits"] = bit_dicts
        entry_dicts.append(entry_dict)

    return chronicle_response({
        "entries": entry_dicts,
    })


@csrf_exempt
def entry(request, entry_id):
    parameters = json.loads(request.body)
    entry = Entry.objects.get(id=entry_id)
    bit_list = parameters["bit_list"]
    entry.bit_list = bit_list
    entry.save()
    return chronicle_response({})

