from PIL import Image

from uploads import exif_helper

def rotated_image(image, exif_dict):
    rotation = exif_helper.rotation_from_exif_dict(exif_dict)
    if rotation:
        image = image.rotate(rotation)
    return image

def thumbnail_of_size(image, size):
    image_copy = image.copy()
    image_copy.thumbnail(size, Image.ANTIALIAS)
    return image_copy

