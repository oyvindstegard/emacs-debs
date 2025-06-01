# Simple unofficial Emacs Debian packages

This project is a single `Makefile` that downloads official Emacs source code
and makes Emacs Debian packages.

Build variants supported:
- PGTK/Wayland build   (package emacs-pgtk)
- GTK/X11 build        (package emacs-x11)
- tty-only build       (e.g. «nox», package emacs-tty)

All variants enable native compilation feature and libtree-sitter support.

The produced deb files are minimal and do not conform to Debian packaging
standards, so they are *not suitable for any public distribution*. But they
should work just fine for local installations.

## Build dependencies on Ubuntu 22.04

- build-essential
- devscripts
- libgtk-3-dev
- libgnutls28-dev
- libjansson-dev
- libgif-dev
- librsvg2-dev
- texinfo
- libncurses-dev
- libgccjit-11-dev
- libm17n-dev
- libxpm-dev
- (libtree-sitter-dev)

## Instructions

These instructions currently apply to Ubuntu 22.04, and may require minimal
adjustments for other Ubuntu or Debian-ishversion. Adapt as needed.

0. Install all regular build-dependencies:

        sudo apt install build-essential devscripts libgtk-3-dev libgnutls28-dev libjansson-dev \
                         libgif-dev librsvg2-dev texinfo libncurses-dev libgccjit-11-dev libm17n-dev \
                         libxpm-dev

1. Install either `libtree-sitter-dev` package from Ubuntu, or create a new package
   for a more recent version locally:

        sudo apt install libtree-sitter-dev
        
   .. or, for locally built and probably more recent version:

        make tree-sitter
        sudo dpkg -i target/libtree-sitter*.deb

2. Make all Emacs variant packages (or just a specific one):

        make [emacs-x11] [emacs-tty] [emacs-pgtk]

3. Install desired deb packages, which are available in `target/*.deb`.

   Note that if you chose to build libtree-sitter locally in step 1, then the
   built Emacs packages will depend on that particular package and not vanilla
   Ubuntu variant.
