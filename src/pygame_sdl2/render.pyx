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
from display cimport *
from surface cimport *
from rwobject cimport to_rwops
from rect cimport to_sdl_rect

from rect import Rect
from error import error
from color import Color
import json
import warnings


cdef class Renderer:
    cdef SDL_Renderer *renderer
    cdef dict _info

    def __cinit__(self):
        self.renderer = NULL

    def __dealloc__(self):
        if self.renderer:
            SDL_DestroyRenderer(self.renderer)

    def __init__(self, Window window=None, vsync=False):
        if window is None:
            window = main_window

        cdef uint32_t flags = SDL_RENDERER_ACCELERATED
        if vsync:
            flags |= SDL_RENDERER_PRESENTVSYNC

        self.renderer = SDL_CreateRenderer(window.window, -1, flags)
        if self.renderer == NULL:
            self.renderer = SDL_GetRenderer(window.window)
            if self.renderer == NULL:
                raise error()

        cdef SDL_RendererInfo rinfo
        if SDL_GetRendererInfo(self.renderer, &rinfo) != 0:
            raise error()

        # Ignore texture_formats for now.
        self._info = {
            "name" : rinfo.name,
            "accelerated" : rinfo.flags & SDL_RENDERER_ACCELERATED != 0,
            "vsync" : rinfo.flags & SDL_RENDERER_PRESENTVSYNC != 0,
            "rtt" : rinfo.flags & SDL_RENDERER_TARGETTEXTURE != 0,
            "max_texture_width" : rinfo.max_texture_width,
            "max_texture_height" : rinfo.max_texture_height,
        }

        if not self.info()["accelerated"]:
            warnings.warn("Renderer is not accelerated.")

    def load_texture(self, fi):
        cdef SDL_Texture *tex
        cdef Texture t = Texture()

        if isinstance(fi, Surface):
            tex = SDL_CreateTextureFromSurface(self.renderer, (<Surface>fi).surface)
        else:
            tex = IMG_LoadTexture_RW(self.renderer, to_rwops(fi), 1)
        if tex == NULL:
            raise error()
        t.set(self.renderer, tex)
        return TextureNode(t)

    def load_atlas(self, fn):
        """ Loads a file in the popular JSON (Hash) format exported by
            TexturePacker and other software. """

        return TextureAtlas(self, fn)

    def clear(self, color):
        if not isinstance(color, Color):
            color = Color(color)
        SDL_SetRenderDrawColor(self.renderer, color.r, color.g, color.b, color.a)
        SDL_RenderClear(self.renderer)

    def render_present(self):
        with nogil:
            SDL_RenderPresent(self.renderer)

    def info(self):
        return self._info

    cdef set_drawcolor(self, col):
        if not isinstance(col, Color):
            col = Color(col)
        SDL_SetRenderDrawColor(self.renderer, col.r, col.g, col.b, col.a)

    def draw_line(self, color not None, x1, y1, x2, y2):
        self.set_drawcolor(color)
        if SDL_RenderDrawLine(self.renderer, x1, y1, x2, y2) != 0:
            raise error()

    def draw_point(self, color not None, x, y):
        self.set_drawcolor(color)
        SDL_RenderDrawPoint(self.renderer, x, y)

    def draw_rect(self, color not None, rect):
        cdef SDL_Rect r
        to_sdl_rect(rect, &r)
        self.set_drawcolor(color)
        SDL_RenderDrawRect(self.renderer, &r)

    def fill_rect(self, color not None, rect):
        cdef SDL_Rect r
        to_sdl_rect(rect, &r)
        self.set_drawcolor(color)
        SDL_RenderFillRect(self.renderer, &r)


cdef class Texture:
    """ Mostly for internal use. Users should only see this for RTT. """

    cdef SDL_Renderer *renderer
    cdef SDL_Texture *texture
    cdef public int w, h

    def __cinit__(self):
        self.texture = NULL

    def __dealloc__(self):
        if self.texture:
            SDL_DestroyTexture(self.texture)

    cdef set(self, SDL_Renderer *ren, SDL_Texture *tex):
        cdef Uint32 format
        cdef int access, w, h

        self.renderer = ren
        self.texture = tex

        if SDL_QueryTexture(self.texture, &format, &access, &w, &h) != 0:
            raise error()

        self.w = w
        self.h = h


cdef class TextureNode:
    """ A specified area of a texture. """

    cdef Texture texture
    cdef SDL_Rect source_rect
    cdef SDL_Rect trimmed_rect
    cdef int source_w
    cdef int source_h

    def __init__(self, tex):
        if isinstance(tex, Texture):
            self.texture = tex
            to_sdl_rect((0,0,tex.w,tex.h), &self.source_rect)
            to_sdl_rect((0,0,tex.w,tex.h), &self.trimmed_rect)
            self.source_w = tex.w
            self.source_h = tex.h

        elif isinstance(tex, TextureNode):
            self.texture = (<TextureNode>tex).texture

        else:
            raise ValueError()

    def render(self, dest=None):
        cdef SDL_Rect dest_rect

        if dest is None:
            with nogil:
                SDL_RenderCopy(self.texture.renderer, self.texture.texture, NULL, NULL)

        else:
            to_sdl_rect(dest, &dest_rect)
            with nogil:
                if dest_rect.w == 0 or dest_rect.h == 0:
                    dest_rect.w = self.trimmed_rect.w
                    dest_rect.h = self.trimmed_rect.h
                SDL_RenderCopy(self.texture.renderer, self.texture.texture, NULL, &dest_rect)


cdef class TextureAtlas:
    cdef object frames

    def __init__(self, Renderer ren, fi):
        jdata = json.load(open(fi, "r"))
        image = jdata["meta"]["image"]

        cdef TextureNode tn = ren.load_texture(image)

        self.frames = {}

        cdef TextureNode itex
        for itm in jdata["frames"].iteritems():
            iname, idict = itm
            itex = TextureNode(tn)
            f = idict["frame"]
            to_sdl_rect((f['x'], f['y'], f['w'], f['h']), &itex.source_rect, "frame")
            f = idict["spriteSourceSize"]
            to_sdl_rect((f['x'], f['y'], f['w'], f['h']), &itex.trimmed_rect, "spriteSourceSize")
            if idict["rotated"]:
                raise error("Rotation not supported yet.")
            itex.source_w = idict["sourceSize"]["w"]
            itex.source_h = idict["sourceSize"]["h"]

            self.frames[iname] = itex

    def __getitem__(self, key):
        return self.frames[key]

    def keys(self):
        return self.frames.keys()


cdef class Sprite:
    """ One or more TextureNodes, with possible transformations. """

    cdef list nodes
    cdef public object pos

    cdef double _rotation
    cdef int _flip
    cdef SDL_Color _color
    cdef double _scalex
    cdef double _scaley

    def __init__(self, nodes):
        self._color.r = 255
        self._color.g = 255
        self._color.b = 255
        self._color.a = 255
        self._scalex = 1.0
        self._scaley = 1.0
        self._flip = SDL_FLIP_NONE
        self.pos = (0,0)

        if isinstance(nodes, TextureNode):
            nodes = [nodes]

        self.nodes = []
        # TODO: Check that they're all from the same texture.
        for node in nodes:
            if not isinstance(node, TextureNode):
                raise ValueError("Invalid argument: %s" % node)
            self.nodes.append(node)

    def render(self, dest=None):
        cdef Texture tex = (<TextureNode>self.nodes[0]).texture
        cdef SDL_Rect dest_rect
        cdef SDL_Rect area_rect
        cdef SDL_Rect *area_ptr = NULL
        cdef SDL_Point pivot

        if dest is None:
            dest = self.pos

        with nogil:
            SDL_SetTextureColorMod(tex.texture, self._color.r, self._color.g, self._color.b)
            SDL_SetTextureAlphaMod(tex.texture, self._color.a)

        cdef TextureNode tn
        for x in self.nodes:
            tn = <TextureNode> x
            to_sdl_rect(dest, &dest_rect, "dest")

            with nogil:
                pivot.x = <int>(self._scalex * (tn.source_w / 2 - tn.trimmed_rect.x))
                pivot.y = <int>(self._scaley * (tn.source_h / 2 - tn.trimmed_rect.y))

                dest_rect.x += <int>(self._scalex * tn.trimmed_rect.x)
                dest_rect.y += <int>(self._scaley * tn.trimmed_rect.y)
                dest_rect.w = <int>(self._scalex * tn.trimmed_rect.w)
                dest_rect.h = <int>(self._scaley * tn.trimmed_rect.h)

                SDL_RenderCopyEx(tex.renderer, tex.texture, &tn.source_rect,
                    &dest_rect, self._rotation, &pivot,
                    <SDL_RendererFlip>self._flip)

    property color:
        def __set__(self, val):
            if not isinstance(val, Color):
                val = Color(val)

            self._color.r = val.r
            self._color.g = val.g
            self._color.b = val.b
            self._color.a = val.a

    property alpha:
        def __get__(self):
            return self._color.a

        def __set__(self, val):
            self._color.a = val

    property rotation:
        def __get__(self):
            return self._rotation

        def __set__(self, val):
            self._rotation = val

    property scale:
        def __get__(self):
            if self._scalex == self._scaley:
                return self._scalex
            else:
                return self._scalex, self._scaley

        def __set__(self, arg):
            if type(arg) == tuple:
                x, y = arg
            else:
                x = y = arg

            self._scalex = x
            self._scaley = y

    property hflip:
        def __get__(self):
            return self._flip & SDL_FLIP_HORIZONTAL

        def __set__(self, val):
            if val:
                self._flip |= SDL_FLIP_HORIZONTAL
            else:
                self._flip &= ~SDL_FLIP_HORIZONTAL

    property vflip:
        def __get__(self):
            return self._flip & SDL_FLIP_VERTICAL

        def __set__(self, val):
            if val:
                self._flip |= SDL_FLIP_VERTICAL
            else:
                self._flip &= ~SDL_FLIP_VERTICAL
