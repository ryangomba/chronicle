import re
import datetime
from PIL.ExifTags import TAGS, GPSTAGS

# TODO this is not cool
TEMP_UTC_OFFSET = datetime.timedelta(hours=-7)


""" Get a dictionary of EXIF data for an image """

def exif_info_for_image(image):
    try:
        exif_info = image._getexif()
    except:
        exif_info = None
    return exif_info

def exif_dict_from_exif_info(exif_info):
    exif_dict = {}
    for tag, value in exif_info.items():
        tag = int(tag)
        decoded = TAGS.get(tag, tag)
        exif_dict[decoded] = value
    gps_info = exif_dict.get("GPSInfo")
    if gps_info:
        decoded_gps_info = {}
        for tag, value in gps_info.items():
            decoded = GPSTAGS.get(tag, tag)
            decoded_gps_info[decoded] = value
        gps_date = decoded_gps_info.get(29)
        if gps_date:
            del decoded_gps_info[29]
            decoded_gps_info["GPSDate"] = gps_date
        exif_dict["GPSInfo"] = decoded_gps_info
    return exif_dict

def exif_dict_for_image(image):
    exif_info = exif_info_for_image(image)
    if exif_info is None:
        return {}
    return exif_dict_from_exif_info(exif_info)

""" Get the rotation from an EXIF dictionary """

def rotation_from_exif_dict(exif_dict):
    if exif_dict:
        orientation = exif_dict.get("Orientation")
        if orientation == 8:
            return 90
        if orientation == 3:
            return 180
        if orientation == 6:
            return 270
    return 0


""" Get a UTC datetime from an EXIF dictionary """

def _datetime_from_date_string(date_string):
    components = re.findall(r'\d+', date_string)
    components = [int(c) for c in components]
    if sum(components) == 0:
        return None

    return datetime.datetime(*components)

def datetime_from_exif_dict(exif_dict):
    if not exif_dict:
        print "WARNING: No EXIF"
        return None

    keys = [
        "DateTimeOriginal",
        "DateTime",
        "DateTimeDigitized",
    ]

    date_string = None
    for key in keys:
        date_string = exif_dict.get(key)
        if date_string:
            exif_dt = _datetime_from_date_string(date_string)
            if exif_dt:
                #print "GOT THE EXIF DATE!"
                return exif_dt
            else:
                print "WARNING: Invalid EXIF datetime"
                pass

    gps_info = exif_dict.get("GPSInfo")
    if gps_info:
        date = gps_info.get("GPSDate")
        time_components = gps_info.get("GPSTimeStamp")
        if date and time_components:
            h, m, ms = [c[0] for c in time_components]
            gps_date_string = "%s %02d:%02d:%02d" % (date, h, m, ms / 100)
            gps_dt = _datetime_from_date_string(gps_date_string)
            if gps_dt:
                #print "GOT THE GPS DATE!"
                return gps_dt + TEMP_UTC_OFFSET
            else:
                print "WARNING: Invalid EXIF GPS datetime"
                pass

    #print "No exif date key; returning created_at dt"
    return None


""" Get coordinates from an EXIF dictionary """

def _convert_to_degress(value):
    d0 = value[0][0]
    d1 = value[0][1]
    d = float(d0) / float(d1)
 
    m0 = value[1][0]
    m1 = value[1][1]
    m = float(m0) / float(m1)
 
    s0 = value[2][0]
    s1 = value[2][1]
    s = float(s0) / float(s1)
 
    return d + (m / 60.0) + (s / 3600.0)
 
def _get_if_exist(data, key):
    if key in data:
        return data[key]
		
    return None

def coordinates_from_exif_dict(exif_dict):
    gps_info = exif_dict.get("GPSInfo")
    if not gps_info:
        return None

    gps_latitude = _get_if_exist(gps_info, "GPSLatitude")
    gps_latitude_ref = _get_if_exist(gps_info, 'GPSLatitudeRef')
    gps_longitude = _get_if_exist(gps_info, 'GPSLongitude')
    gps_longitude_ref = _get_if_exist(gps_info, 'GPSLongitudeRef')

    if gps_latitude and gps_latitude_ref and gps_longitude and gps_longitude_ref:
        lat = _convert_to_degress(gps_latitude)
        if gps_latitude_ref != "N":                     
            lat = 0 - lat
        lon = _convert_to_degress(gps_longitude)
        if gps_longitude_ref != "E":
            lon = 0 - lon
        return lat, lon

    return None

