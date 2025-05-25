# Emacs Debian package

## Build dependencies on Ubuntu 22.04

- build-essential
- devscripts
- libgtk-3-dev
- libgnutls28-dev
- libjansson-dev
- libgif-dev
- librsvg2-dev
- libtree-sitter
- texinfo
- libncurses-dev
- libgccjit-11-dev
- libm17n-dev

## Instructions

0. Install all build-dependencies:

        # Ensure a build of libtree-sitter is installed in /usr/local first
        # Then:

        sudo apt-get install build-essential devscripts libgtk-3-dev libgnutls28-dev libjansson-dev libgif-dev librsvg2-dev texinfo libncurses-dev libgccjit-11-dev libm17n-dev

1. Run top level `make` to download Emacs source code distribution and copy debian/-files into it.

2. ...
