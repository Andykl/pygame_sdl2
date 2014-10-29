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

cdef class Rect:

    def __init__(self, *args):

        cdef int x, y, w, h

        len_args = len(args)

        if len_args == 1:

            if isinstance(args, Rect):
                x = args[0].x
                y = args[0].y
                w = args[0].w
                h = args[0].h

            else:
                if len(args) == 4:
                    x, y, w, h = args[0]
                elif len(args) == 2:
                    x, y = args[0]
                    w = 0
                    h = 0
                else:
                    raise TypeError("Argument must be a rect style object.")

        elif len_args == 2:
            (x, y) = args[0]
            (w, h) = args[1]

        elif len_args == 4:
            x, y, w, h = args

        else:
            raise TypeError("Argument must be a rect style object.")

        self.x = x
        self.y = y
        self.w = w
        self.h = h


cdef int to_sdl_rect(rectlike, SDL_Rect *rect, argname=None) except -1:
    """
    Converts `rectlike` to the SDL_Rect `rect`.

    `rectlike` may be a Rect or a (x, y, w, h) tuple.
    """

    cdef int x, y, w, h
    cdef Rect rl

    if isinstance(rectlike, Rect):
        rl = rectlike

        rect.x = rl.x
        rect.y = rl.y
        rect.w = rl.w
        rect.h = rl.h

        valid = 1

    elif isinstance(rectlike, (tuple, list)):

        if len(rectlike) == 4:
            rect.x, rect.y, rect.w, rect.h = rectlike
            return 0

        elif len(rectlike) == 2:
            rect.x, rect.y = rectlike
            rect.w, rect.h = rectlike
            return 0

    if argname:
        raise TypeError("Argument {} must be a rect style object.".format(argname))
    else:
        raise TypeError("Argument must be a rect style object.")
