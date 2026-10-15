import struct
def parse_attrs(b):
    if not b: return {}
    p = 0; n, = struct.unpack_from('<I', b, p); p += 4; out = {}
    def rs():
        nonlocal p
        l, = struct.unpack_from('<I', b, p); s = b[p+4:p+4+l]; p += 4 + l; return s
    for _ in range(n):
        k = rs().decode(); t = b[p]; p += 1
        if t == 0x02: v = rs().decode('utf8', 'replace')
        elif t == 0x03: v = bool(b[p]); p += 1
        elif t == 0x05: v, = struct.unpack_from('<f', b, p); p += 4
        elif t == 0x06: v, = struct.unpack_from('<d', b, p); p += 8
        elif t == 0x09: v = struct.unpack_from('<fifi', b, p); p += 16  # UDim2? (UDim = 8)
        elif t == 0x0F: v = struct.unpack_from('<3f', b, p); p += 12  # Color3
        elif t == 0x0E: v = struct.unpack_from('<2f', b, p); p += 8
        elif t == 0x11: v = struct.unpack_from('<3f', b, p); p += 12  # Vector3
        elif t == 0x15: v = struct.unpack_from('<2f', b, p); p += 8   # NumberRange
        else: raise ValueError('attr type %x key %s' % (t, k))
        out[k] = v
    return out
def write_attrs(d, types):
    out = struct.pack('<I', len(d))
    for k, v in d.items():
        kb = k.encode(); out += struct.pack('<I', len(kb)) + kb
        t = types.get(k)
        if isinstance(v, bool): out += b'\x03' + bytes([v])
        elif isinstance(v, str): vb = v.encode(); out += b'\x02' + struct.pack('<I', len(vb)) + vb
        elif isinstance(v, (int, float)) and t != 0x05: out += b'\x06' + struct.pack('<d', v)
        elif t == 0x05: out += b'\x05' + struct.pack('<f', v)
        else: raise ValueError(k)
    return out
