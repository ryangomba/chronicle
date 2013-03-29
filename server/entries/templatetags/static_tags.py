from django import template
from django.utils.safestring import mark_safe

from chronicle import settings

register = template.Library()

@register.simple_tag
def css_tag(format_string):
    return mark_safe('<link rel="stylesheet" href="%scss/%s" type="text/css" />' % (
        settings.STATIC_URL, format_string))

@register.simple_tag
def js_tag(format_string):
    return mark_safe('<script type="text/javascript" src="%sjs/%s"></script>' % (
        settings.STATIC_URL, format_string))

