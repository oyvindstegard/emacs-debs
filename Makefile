# Download and prepare source package for building.

EMACS_VERSION = 30.1

DOWNLOAD_URL = https://www.nic.funet.fi/pub/gnu/ftp.gnu.org/pub/gnu/emacs/emacs-$(EMACS_VERSION).tar.gz
DOWNLOAD_FILE = emacs_$(EMACS_VERSION).orig.tar.gz

DEBIAN_SRC_FILES = $(shell find debian/ -type f -name '*')
DEBIAN_DEST_FILES = $(addprefix emacs-$(EMACS_VERSION)/,$(DEBIAN_SRC_FILES))

all: $(DEBIAN_DEST_FILES)

emacs-$(EMACS_VERSION)/debian/%: debian/% | emacs-$(EMACS_VERSION)/debian
	cp $< $@

emacs-$(EMACS_VERSION)/debian: | emacs-$(EMACS_VERSION)
	mkdir -p emacs-$(EMACS_VERSION)/debian

emacs-$(EMACS_VERSION): $(DOWNLOAD_FILE)
	tar -xvf $(DOWNLOAD_FILE)

$(DOWNLOAD_FILE):
	@echo Downloading Emacs version $(EMACS_VERSION)
	@echo
	wget $(DOWNLOAD_URL) -O $@

clean:
	rm -f emacs_$(EMACS_VERSION).orig.tar.gz
	rm -rf emacs-$(EMACS_VERSION)

.PHONY: all clean
