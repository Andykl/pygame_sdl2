# Copyright 2014 Tom Rothamel <tom@rothamel.us>
# Copyright 2014 Patrick Dawson <pat@dw.is>
#
# This software is provided 'as-is', without any express or implied
# warranty.  In no event will the authors be held liable for any damages
# arising from the use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 3. This notice may not be removed or altered from any source distribution.

from sdl2 cimport *
import binascii
import struct

include "color_dict.pxi"

cdef Uint32 map_color(SDL_Surface *surface, color) except? 0xaabbccdd:
    """
    Maps `color` into an RGBA color value that can be used with `surface`.
    """

    cdef Uint8 r, g, b, a

    if isinstance(color, (tuple, Color)) and len(color) == 4:
        r, g, b, a = color
    elif isinstance(color, (tuple, Color)) and len(color) == 3:
        r, g, b = color
        a = 255
    else:
        raise TypeError("Expected a color.")

    return SDL_MapRGBA(surface.format, r, g, b, a)

cdef object get_color(Uint32 pixel, SDL_Surface *surface):
    cdef Uint8 r
    cdef Uint8 g
    cdef Uint8 b
    cdef Uint8 a

    SDL_GetRGBA(pixel, surface.format, &r, &g, &b, &a)

    return (r, g, b, a)

cdef class Color:
    cdef from_rgba(self, Uint8 r, Uint8 g, Uint8 b, Uint8 a):
        self.r = r
        self.g = g
        self.b = b
        self.a = a

    cdef from_hex(self, c):
        if len(c) == 3:
            pass
        elif len(c) == 4:
            pass

        try:
            if len(c) == 6:
                r, g, b = struct.unpack('BBB', binascii.unhexlify(c))
                a = 255
            elif len(c) == 8:
                r, g, b, a = struct.unpack('BBBB', binascii.unhexlify(c))
        except TypeError as e:
            raise ValueError(str(c))

        self.from_rgba(r, g, b, a)

    cdef from_name(self, c):
        # Remove all whitespace.
        c = "".join(c.split()).lower()

        try:
            r, g, b = colors[c]
        except KeyError as e:
            raise ValueError(c)
        self.from_rgba(r, g, b, 255)

    def __richcmp__(Color x, y, int op):
        if op == 3:
            return not (x == y)

        if isinstance(y, tuple):
            y = Color(y)
        if not isinstance(y, Color):
            return False
        if op == 2:
            return x.r == y.r and x.g == y.g and x.b == y.b and x.a == y.a

    def __init__(self, *args):
        self.length = 4
        if len(args) == 1:
            c = args[0]
            if isinstance(c, str):
                if c.startswith('#'):
                    self.from_hex(c[1:])
                elif c.startswith('0x'):
                    self.from_hex(c[2:])
                else:
                    self.from_name(c)
            elif isinstance(c, (tuple, Color)):
                if len(c) == 4:
                    self.from_rgba(c[0], c[1], c[2], c[3])
                elif len(c) == 3:
                    self.from_rgba(c[0], c[1], c[2], 255)
                else:
                    raise ValueError(c)
            else:
                self.from_hex("%08x" % c)

        elif len(args) == 3:
            r, g, b = args
            self.from_rgba(r, g, b, 255)
        elif len(args) == 4:
            r, g, b, a = args
            self.from_rgba(r, g, b, a)

    def __repr__(self):
        return str((self.r, self.g, self.b, self.a))

    def __int__(self):
        packed = struct.pack('BBBB', self.r, self.g, self.b, self.a)
        return struct.unpack('>L', packed)[0]

    def __hex__(self):
        return "0x%02x%02x%02x%02x" % (self.r, self.g, self.b, self.a)

    def __oct__(self):
        return oct(int(self))

    def __float__(self):
        return float(int(self))

    def __reduce__(self):
        d = {}
        d['rgba'] = (self.r, self.g, self.b, self.a)
        return (Color, (), d)

    def __setstate__(self, d):
        self.r, self.g, self.b, self.a = d['rgba']

    def __setitem__(self, key, val):
        if not isinstance(val, int):
            raise ValueError(val)
        if key >= self.length:
            raise IndexError(key)
        if val < 0 or val > 255:
            raise ValueError(val)

        if key == 0: self.r = val
        elif key == 1: self.g = val
        elif key == 2: self.b = val
        elif key == 3: self.a = val
        else:
            raise IndexError(key)

    def __getitem__(self, key):
        if isinstance(key, slice):
            return tuple(self)[key]
        if key >= self.length:
            raise IndexError(key)
        if key == 0: return self.r
        elif key == 1: return self.g
        elif key == 2: return self.b
        elif key == 3: return self.a
        else:
            raise IndexError(key)

    def __len__(self):
        return self.length

    def normalize(self):
        return self.r / 255.0, self.g / 255.0, self.b / 255.0, self.a / 255.0

    def correct_gamma(self, gamma):
        m = map(lambda x: int(round(pow(x / 255.0, gamma) * 255)), tuple(self))
        c = Color(tuple(m))
        return c

    def set_length(self, n):
        if n > 4 or n < 1:
            raise ValueError(n)
        self.length = n
