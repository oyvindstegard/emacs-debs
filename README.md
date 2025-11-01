# Build simple Emacs debs for Ubuntu/Debian

This project is a single `Makefile` that downloads official Emacs source code
releases and makes Debian packages.

Current Emacs version: **30.2**

Current default Ubuntu version: **22.04** (**24.04** works as well)

Build variants supported:
- PGTK/Wayland build   (package emacs-pgtk)
- GTK/X11 build        (package emacs-x11)
- tty-only build       (package emacs-tty, aka «emacs-nox»)

All variants enable native compilation feature and tree-sitter support.

The produced deb files are minimal and do not conform to Debian packaging
standards, so they are *not suitable for any public distribution*. But they
should work just fine for local installations. The packages install Emacs under
`/usr/local/`, which is a not typical for Debian. This is done to reduce chance
of conflicts with official packages from elsewhere.

## Build dependencies on Ubuntu

- build-essential
- devscripts
- libgtk-3-dev
- libgnutls28-dev
- libgif-dev
- librsvg2-dev
- texinfo
- libncurses-dev
- libgccjit-11-dev
- libm17n-dev
- libxpm-dev
- (libtree-sitter-dev)

## Building directly on your host

These instructions currently apply to a build host running Ubuntu 22.04.
Adjustments for other Ubuntu versions or Debian-ish may be required.

If you have Docker or similar, see the [Building with a container](#container)-instructions if
you want to avoid installing all of these Emacs build dependencies directly on
your host and instead do the builds inside of a container.

1. Install all regular build-dependencies:

        sudo apt install build-essential lsb-release devscripts libgtk-3-dev libgnutls28-dev \
                         libgif-dev librsvg2-dev texinfo libncurses-dev libgccjit-11-dev libm17n-dev \
                         libxpm-dev

2. Build and install libtree-sitter package:

        make tree-sitter
        sudo dpkg -i target/libtree-sitter*.deb

3. Make all Emacs variant packages:

        make

4. Install desired deb packages, which are available in `target/*.deb`:

        sudo apt install ./target/emacs-pgtk*.deb ./target/libtree-sitter*.deb

## Building within a container             <a name="container"></a>

These instructions use Docker and offer more flexibility and a cleaner approach
with regard to build environment.

1. First build a container image for desired Ubuntu version:

        docker build --build-arg ubuntu=22.04 . -t emacs-debs:22.04
        
   (For Ubuntu 24.04, just replace the version number in `--build-arg ubuntu=..`
   and image tag.)

2. Run a container which builds all Emacs variants:

        docker run --name emacs-debs emacs-debs:22.04
        
   If you just need a specific variant, like emacs-pgtk (Wayland build), then add
   that as an argument instead:
   
        docker run --name emacs-debs emacs-debs:22.04 emacs-pgtk
        
3. Copy deb packages from container file system to host file system and delete container:

        make clean && docker cp emacs-debs:/home/builder/target .

4. Clean up Docker container:

        docker container rm -v emacs-debs

5. Install desired deb packages, which are available in `target/*.deb`:

        sudo apt install ./target/emacs-pgtk*.deb ./target/libtree-sitter*.deb

   Please note that the build variant packages all conflict with each other, and
   only one of them can be installed at any time.
