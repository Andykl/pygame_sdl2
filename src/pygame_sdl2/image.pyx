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
from sdl2_image cimport *
from surface cimport *
from rwobject cimport to_rwops
import os
from error import error
import pygame_sdl2

cdef int image_formats = 0

def init():
    global image_formats
    image_formats = IMG_Init(IMG_INIT_JPG | IMG_INIT_PNG | IMG_INIT_TIF | IMG_INIT_WEBP)
    if image_formats == 0:
        raise error()

init()

def quit(): # @ReservedAssignment
    IMG_Quit()

cdef process_namehint(namehint):
    # Accepts "foo.png", ".png", or "png"
    ext = os.path.splitext(namehint)[1]
    if ext == '':
        ext = namehint
    if ext[0] == '.':
        ext = ext[1:]
    return ext.upper()

def load(fi, namehint=""):
    cdef SDL_Surface *img

    cdef SDL_RWops *rwops
    cdef char *ftype

    # IMG_Load_RW can't load TGA images.
    if isinstance(fi, str):
        if fi.lower().endswith('.tga'):
            namehint = "TGA"

    rwops = to_rwops(fi)

    if namehint == "":
        with nogil:
            img = IMG_Load_RW(rwops, 1)

    else:
        namehit = process_namehint(namehint)
        ftype = namehint

        with nogil:
            img = IMG_LoadTyped_RW(rwops, 1, ftype)

    if img == NULL:
        raise error()
    cdef Surface surf = Surface(())
    surf.surface = img
    surf.owns_surface = True

    if img.format.BitsPerPixel == 32:
        return surf

    cdef int n = 0
    has_alpha = False

    if img.format.Amask:
        has_alpha = True
    elif img.format.palette != NULL:
        # Check for non-opaque palette colors.
        while n < img.format.palette.ncolors:
            if img.format.palette.colors[n].a != 255:
                has_alpha = True
                break
            n += 1

    try:
        if has_alpha:
            return surf.convert_alpha()
        else:
            return surf.convert()
    except error:
        return surf

def save(Surface surface not None, filename):
    ext = os.path.splitext(filename)[1]
    ext = ext.upper()
    err = 0

    cdef char *fn = filename
    cdef SDL_RWops *rwops

    if ext == '.PNG':
        with nogil:
            err = IMG_SavePNG(surface.surface, fn)
    elif ext == '.BMP':
        rwops = to_rwops(filename, "wb")
        with nogil:
            err = SDL_SaveBMP_RW(surface.surface, rwops, 1)
    else:
        raise ValueError("Unsupported format: %s" % ext)

    if err != 0:
        raise error()

def get_extended():
    # This may be called before init.
    return True
