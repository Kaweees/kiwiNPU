from cocotb.types import LogicArray, Range

def pack_values(values: list[int], width: int) -> LogicArray:
    """Pack a list of integers into a single LogicArray."""
    total_bits = len(values) * width

    # Construct the packed integer
    # values[0] is at LSB, values[-1] is at MSB
    result = 0
    for val in reversed(values):
        # Mask to width to ensure we pack correctly
        val = val & ((1 << width) - 1)
        result = (result << width) | val

    return LogicArray(result, Range(total_bits - 1, "downto", 0))


def get_signed_value(val: int, width: int) -> int:
    """Convert unsigned bit representation to signed integer (two's complement)."""
    if val >= (1 << (width - 1)):
        # Sign extend if negative
        return val - (1 << width)
    return val


def unpack_values(packed_value: LogicArray, num_values: int, width: int) -> list[int]:
    """Unpack a packed integer into a list of signed integers."""
    values = []
    mask = (1 << width) - 1
    for i in range(num_values):
        # Extract the bits for this element
        val = (packed_value.integer >> (i * width)) & mask
        values.append(get_signed_value(val, width))
    return values
