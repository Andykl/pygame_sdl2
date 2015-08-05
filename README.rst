===========
Pygame_sdl2
===========

Pygame_sdl2 is a reimplementation of the Pygame API using SDL2 and
related libraries. The initial goal of this project are to allow
games written using the pygame API to run on SDL2 on desktop and
mobile  platforms. We will then evolve the API to expose SDL2-provided
functionality in a pythonic manner.

License
-------

New code written for pygame_sdl2 is licensed under the Zlib license. Some
code - including compiled code - is taken wholesale from Pygame, and is
licensed under the LGPL2. Please check each module to
determine its licensing status.

See the COPYING.ZLIB and COPYING.LGPL21 files for details - you'll need
to comply with both to distribute software containing pygame_sdl2.

Current Status
--------------

Pygame_sdl2 builds and runs on Windows, Mac OS X, and Linux, with a useful
subset of the pygame API working. The following modules have at least
some implementation:

* pygame_sdl2.color
* pygame_sdl2.display
* pygame_sdl2.draw
* pygame_sdl2.event
* pygame_sdl2.font
* pygame_sdl2.gfxdraw
* pygame_sdl2.image
* pygame_sdl2.joystick
* pygame_sdl2.key
* pygame_sdl2.locals
* pygame_sdl2.mixer (including mixer.music)
* pygame_sdl2.mouse
* pygame_sdl2.scrap
* pygame_sdl2.sprite
* pygame_sdl2.surface
* pygame_sdl2.sysfont
* pygame_sdl2.time
* pygame_sdl2.transform
* pygame_sdl2.version

Experimental new modules include:

* pygame_sdl2.render

Current omissions include:

* Modules not listed above.

* APIs that expose pygame data as buffers or arrays.

* Support for non-32-bit surface depths. Our thinking is that 8, 16,
  and (to some extent) 24-bit surfaces are legacy formats, and not worth
  duplicating code four or more times to support. This only applies to
  in-memory formats - when an image of lesser color depth is loaded, it
  is converted to a 32-bit image.

* Support for palette functions, which only apply to 8-bit surfaces.


Documentation
-------------

There isn't much pygame_sdl2 documentation at the moment, especially for
end-users. Check out the pygame documentation at:

    http://www.pygame.org/docs/

There have been a few additions to the Pygame API.

Importing as pygame
^^^^^^^^^^^^^^^^^^^

::

    import pygame_sdl2
    pygame_sdl2.import_as_pygame()

Will modify sys.modules so that pygame_sdl2 modules are used instead of
their pygame equivalents. For example, after running the code above,
the code::

    import pygame.image
    img = pygame.image.load("logo.png")

will use pygame_sdl2 to load the image, instead of pygame. (This is intended
to allow code to run on pygame_sdl2 or pygame.)

Mobile
^^^^^^

Pygame_sdl2 exposes the SDL2 application lifecycle events, which are
used to pause and resume the application on mobile platforms. The most
useful events are:

APP_WILLENTERBACKGROUND
    Generated when the app will enter the background. The app should
    immediately stop drawing the screen and playing sounds. It should
    save its state, as the application may be killed at any time
    after this event has been handled.

APP_DIDENTERFOREGROUND
    Generated when the app will enter the foreground. The app should
    delete the saved state (as it is no longer needed), and resume
    drawing the screen and playing sounds.

In addition, the set of keycodes now include the SDL2 application
control keyboard codes. Most notably, pygame_sdl2.K_AC_BACK is the
code for the Android back button.


Text Input
^^^^^^^^^^

Several functions have been added to allow more complex text input.

.. function:: pygame_sdl2.key.start_text_input()

    Starts text input. If an on-screen keyboard is supported, it is shown.

.. function:: pygame_sdl2.key.def stop_text_input()

    Stops text input and hides the on-screen keyboard.

.. function:: pygame_sdl2.key.set_text_input_rect(rect)

    Sets the text input rectangle. This is used by input methods and, on
    some platforms, to ensure the text is not blocked by an on-screen
    keyboard.

.. function:: pygame_sdl2.key.has_screen_keyboard_support()

    Returns true of the platform supports an on-screen keyboard.

.. function:: pygame_sdl2.key.is_screen_keyboard_shown(Window window=None)

    Returns true if the on-screen keyboard is shown.

During text input, the unicode field of the KEYDOWN object is not set.
Instead, two new events are generated:

TEXTINPUT
    Generated when text has been added.

    `text`
        The text that has been added.


TEXTEDITING
    Used when text is being edited by an input method (IME).

    `text`
        The text that is being edited. This is usually displayed
        underlined.

    `start`, `length`
        Used by IMEs to display text being actively edited. This is
        generaly displayed with a thicker underline.

Mouse Wheel
^^^^^^^^^^^

.. function:: pygame.event.set_mousewheel_buttons(flag)

    When `flag` is true (the default), the vertical mouswheel is mapped to
    buttons 4 and 5, with mousebuttons 4 and greater being offset by 2.

    When flag is false, the mousebuttons retain their numbers, and
    MOUSEWHEEL events are generated.

.. function:: pygame.event.get_mousewheel_buttons()

    Returns the mousewheel buttons flag.

MOUSEWHEEL
    Generated by mousewheel motion.

    `x`
        The amount of motion of the mousewheel in the x axis.
    `y`
        The amount of motion of the mousewheel in the y axis.

HighDPI/Retina
^^^^^^^^^^^^^^

When the pygame.WINDOW_ALLOW_HIGHDPI flag is passed to pygame.display.set_mode,
opengl surfaces can be created in HighDPI/Retina mode. When this occurs, the
drawable size of a window will be larger than the size of the window.

.. function:: pygame.display.get_drawable_size()

    Gets the drawable size of the window created with pygame.display.set_mode()


Building
--------

Building pygame_sdl2 requires the ability to build python modules; the
ability to link against the SDL2, SDL2_gfx, SDL2_image, SDL2_mixer,
and SDL2_ttf libraries; and the ability to compile cython code.

To build pygame_sdl2, install the build dependencies:

**Ubuntu**::

    sudo apt-get install build-essential python-dev libsdl2-dev \
        libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev \
        libjpeg-dev libpng12-dev virtualenvwrapper

**Mac OS X** (with `brew <http://brew.sh>`_)::

    brew install sdl2 sdl2_gfx sdl2_image sdl2_mixer sdl2_ttf
    sudo pip install virtualenvwrapper

Open a new shell to ensure virtualenvwrapper is running, then run::

    mkvirtualenv pygame_sdl2
    pip install cython

Change into a clone of this project, and run the following command to modify
the virtualenv so pygame_sdl2 header files can be installed in it::

    python fix_virtualenv.py

Finally, build and install pygame_sdl2 by running::

    python setup.py install

Contributing
------------

We're looking for people to contribute to pygame_sdl2 development. For
simple changes, just give us a pull request. Before making a change that
is a lot of work, it might make sense to send us an email to ensure we're
not already working on it.

Credits
-------

Pygame_sdl2 is written by:

* Patrick Dawson <pat@dw.is>
* Tom Rothamel <tom@rothamel.us>

It includes some code from Pygame, and is inspired by the hundreds of
contributors to the Pygame, Python, and SDL2 projects.
