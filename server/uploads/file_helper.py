import hashlib

def md5_for_file(f):
    f.seek(0)
    md5 = hashlib.md5()
    for chunk in iter(lambda: f.read(128 * md5.block_size), b''):
        md5.update(chunk)
    return md5.hexdigest()

def md5_for_string(s):
    md5 = hashlib.md5()
    md5.update(s)
    return md5.hexdigest()

