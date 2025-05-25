# Download and prepare source package for building.

EMACS_VERSION ::= 30.1

DEB_VER ::= $(EMACS_VERSION)-1
DEB_ARCH ::= $(shell dpkg --print-architecture)
DISTRO ::= $(shell lsb_release -sir|tr A-Z a-z|tr -d \\n)

DOWNLOAD_URL ::= https://www.nic.funet.fi/pub/gnu/ftp.gnu.org/pub/gnu/emacs/emacs-$(EMACS_VERSION).tar.gz
DOWNLOAD_FILE ::= emacs_$(EMACS_VERSION).orig.tar.gz

BUILDDIR ::= build
OBJDIR ::= target

all: emacs-pgtk emacs-tty
	@echo $(DISTRO)

$(DOWNLOAD_FILE):
	@echo Downloading Emacs version $(EMACS_VERSION)
	@echo
	wget $(DOWNLOAD_URL) -O $@

$(BUILDDIR)/pgtk/emacs-$(EMACS_VERSION): $(DOWNLOAD_FILE)
	mkdir -p $(BUILDDIR)/pgtk
	tar -C $(BUILDDIR)/pgtk -xvf $(DOWNLOAD_FILE)

$(BUILDDIR)/pgtk/build.compiled: | $(BUILDDIR)/pgtk/emacs-$(EMACS_VERSION)
	$(MAKE) -C $(BUILDDIR)/pgtk/emacs-$(EMACS_VERSION) distclean
	cd $(BUILDDIR)/pgtk/emacs-$(EMACS_VERSION) && ./configure --prefix=$(abspath $(BUILDDIR)/pgtk/install/usr/local) --with-pgtk
	$(MAKE) -C $(BUILDDIR)/pgtk/emacs-$(EMACS_VERSION) -j8
	touch $(BUILDDIR)/pgtk/build.compiled

$(BUILDDIR)/pgtk/build.installed: $(BUILDDIR)/pgtk/build.compiled
	$(MAKE) -C $(BUILDDIR)/pgtk/emacs-$(EMACS_VERSION) install-strip
	touch $(BUILDDIR)/pgtk/build.installed

$(BUILDDIR)/pgtk/build.shlibdeps: $(BUILDDIR)/pgtk/build.installed $(BUILDDIR)/pgtk/install/usr/local/bin/emacs
	mkdir -p $(BUILDDIR)/pgtk/debian && touch $(BUILDDIR)/pgtk/debian/control
	cd $(dir $@) && dpkg-shlibdeps -O --ignore-missing-info -e install/usr/local/bin/emacs > $(notdir $@) || { rm -f $(notdir $@); exit 1; }
	sed -i -e 's/^shlibs:Depends=//' $@
	rm $(BUILDDIR)/pgtk/debian/control && rmdir $(BUILDDIR)/pgtk/debian

$(BUILDDIR)/pgtk/install/DEBIAN/changelog: debian/changelog
	cp debian/changelog $@

$(BUILDDIR)/pgtk/install/DEBIAN/control: $(BUILDDIR)/pgtk/build.shlibdeps debian/control_template_pgtk
	mkdir -p $(dir $@)
	sed -e "s#%{build.shlibdeps}#`cat build/pgtk/build.shlibdeps`#" -e 's#%{build.version}#'$(DEB_VER)'#' debian/control_template_pgtk > $@

$(OBJDIR)/emacs-pgtk_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb: $(BUILDDIR)/pgtk/build.shlibdeps $(BUILDDIR)/pgtk/install/DEBIAN/control $(BUILDDIR)/pgtk/install/DEBIAN/changelog
	mkdir -p $(OBJDIR)
	fakeroot dpkg-deb -b $(BUILDDIR)/pgtk/install $(OBJDIR)
	mv -f $(OBJDIR)/emacs-pgtk_$(DEB_VER)_$(DEB_ARCH).deb $(OBJDIR)/emacs-pgtk_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb

emacs-pgtk: $(OBJDIR)/emacs-pgtk_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb

clean:
	rm -f emacs_$(EMACS_VERSION).orig.tar.gz
	rm -rf build/ target/

.PHONY: all clean emacs-pgtk emacs-tty
