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
- libxpm-dev

## Instructions

0. Install all build-dependencies:

        # Ensure a build of libtree-sitter is installed in /usr/local first
        # Then:

        sudo apt-get install build-essential devscripts libgtk-3-dev libgnutls28-dev libjansson-dev libgif-dev librsvg2-dev texinfo libncurses-dev libgccjit-11-dev libm17n-dev libxpm-dev

1. Make and install libtree-sitter deb:

        make tree-sitter
        sudo dpkg -i target/libtree-sitter*.deb

2. Make all Emacs packages:

        make

3. Distribute and install desired packages built under `target/`.
   All emacs-packages depend on libtree-sitter deb, in addition to other system
   packages.
