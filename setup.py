#!/usr/bin/env python

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

from setuplib import android, ios, cython, pymodule, setup, parse_cflags, parse_libs, find_unnecessary_gen
import os

if android or ios:
    sdl_libs = [ 'SDL2' ]
else:
    parse_cflags([ "sh", "-c", "sdl2-config --cflags" ])
    sdl_libs = parse_libs([ "sh", "-c", "sdl2-config --libs" ])

pymodule("pygame_sdl2.__init__")
pymodule("pygame_sdl2.compat")
pymodule("pygame_sdl2.threads.__init__")
pymodule("pygame_sdl2.threads.Py25Queue")
pymodule("pygame_sdl2.sprite")
pymodule("pygame_sdl2.sysfont")
pymodule("pygame_sdl2.version")

cython("pygame_sdl2.error", libs=sdl_libs)
cython("pygame_sdl2.color", libs=sdl_libs)
cython("pygame_sdl2.rect", libs=sdl_libs)
cython("pygame_sdl2.rwobject", libs=sdl_libs)
cython("pygame_sdl2.surface", libs=sdl_libs)
cython("pygame_sdl2.display", libs=sdl_libs)
cython("pygame_sdl2.event", libs=sdl_libs)
cython("pygame_sdl2.locals", libs=sdl_libs)
cython("pygame_sdl2.key", libs=sdl_libs)
cython("pygame_sdl2.mouse", libs=sdl_libs)
cython("pygame_sdl2.joystick", libs=sdl_libs)
cython("pygame_sdl2.time", libs=sdl_libs)
cython("pygame_sdl2.image", libs=['SDL2_image'] + sdl_libs)
cython("pygame_sdl2.transform", libs=['SDL2_gfx'] + sdl_libs)
cython("pygame_sdl2.gfxdraw", libs=['SDL2_gfx'] + sdl_libs)
cython("pygame_sdl2.draw", libs=sdl_libs)
cython("pygame_sdl2.font", libs=['SDL2_ttf'] + sdl_libs)
cython("pygame_sdl2.mixer", libs=['SDL2_mixer'] + sdl_libs)
cython("pygame_sdl2.mixer_music", libs=['SDL2_mixer'] + sdl_libs)
cython("pygame_sdl2.scrap", libs=sdl_libs)
cython("pygame_sdl2.render", libs=['SDL2_image'] + sdl_libs)

if "PYGAME_SDL2_INSTALL_HEADERS" in os.environ:
    headers = [
        "src/pygame_sdl2/pygame_sdl2.h",
        "gen/pygame_sdl2.rwobject_api.h",
        "gen/pygame_sdl2.surface_api.h",
        "gen/pygame_sdl2.display_api.h",
        ]
else:
    headers = [ ]

setup("pygame_sdl2", "0.1", headers=headers)

find_unnecessary_gen()
