import json
from django.http import HttpResponse
from datetime import datetime, timedelta

DATETIME_EPOCH = datetime(1970, 1, 1)

def timestamp_from_datetime(datetime_value):
    return (datetime_value - DATETIME_EPOCH).total_seconds()

def datetime_from_timestamp(timestamp_value):
    return DATETIME_EPOCH + timedelta(seconds=timestamp_value)

def chronicle_response(dictionary):
    json_string = json.dumps(dictionary)
    mimetype = "application/json"
    return HttpResponse(json_string, mimetype=mimetype)

def json_response(json_dict):
    return HttpResponse(
        json.dumps(json_dict),
        status=200,
        mimetype="application/json"
    )

def json_error(error_code, error_message):
    return HttpResponse(
        json.dumps({'error': error_message}),
        status=error_code,
        mimetype="application/json"
    )

