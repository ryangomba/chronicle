import datetime as dt

def day_for_datetime(datetime):
    delta = datetime - dt.datetime(1900, 1, 1)
    return delta.days + 1

def datetime_range_for_day(day):
    start = dt.datetime(1900, 1, 1) + dt.timedelta(day, 0, 0)
    end = start + dt.timedelta(1, 0, 0) - dt.timedelta(0, 0, 1)
    return start, end

def bit_id_for_bit(bit):
    return "%d_%s" % (bit.kind, bit.id)

def order_string_for_bits(bits):
    return [bit_id_for_bit(bit) for b in bits].join(",")

def ordered_bits_from_string(bits, string):
    ordered_bit_ids = string.split(",")

    ordered_bits = []
    unordered_bits = bits
    for bit_id in ordered_bit_ids:
        for i, bit in enumerate(unordered_bits):
            if bit_id_for_bit(bit) == bit_id:
                ordered_bits.append(bit)
                del unordered_bits[i]
                break

    return ordered_bits + unordered_bits

