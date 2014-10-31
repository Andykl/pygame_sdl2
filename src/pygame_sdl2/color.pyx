# Copyright 2014 Tom Rothamel <tom@rothamel.us>
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

cdef Uint32 map_color(SDL_Surface *surface, color) except? 0xaabbccdd:
    """
    Maps `color` into an RGBA color value that can be used with `surface`.
    """

    cdef Uint8 r, g, b, a

    if isinstance(color, tuple) and len(color) == 4:
        r, g, b, a = color
    elif isinstance(color, tuple) and len(color) == 3:
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
