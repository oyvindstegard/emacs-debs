# Download, build and make deb packages of Emacs (and libtree-sitter) on
# Debian-ish. All packages install files to /usr/local to avoid file conflicts
# with other official packages.

# Emacs upstream release:
EMACS_VERSION ::= 30.1
# Tree sitter upstream release:
TS_VERSION ::= 0.25.4

DEB_VER ::= $(EMACS_VERSION)-1
DEB_ARCH ::= $(shell dpkg --print-architecture)
DISTRO ::= $(shell lsb_release -sir|tr A-Z a-z|tr -d \\n)

DOWNLOAD_URL ::= https://www.nic.funet.fi/pub/gnu/ftp.gnu.org/pub/gnu/emacs/emacs-$(EMACS_VERSION).tar.gz
DOWNLOAD_FILE ::= emacs_$(EMACS_VERSION).orig.tar.gz

BUILDDIR ::= build
OBJDIR ::= target

all: emacs-pgtk emacs-tty emacs-x11

$(DOWNLOAD_FILE):
	@echo Downloading Emacs version $(EMACS_VERSION)
	@echo
	wget $(DOWNLOAD_URL) -O $@

# Params: $(1) Emacs variant build dir, $(2) extra config flags
define configure_and_build
	$(MAKE) -C $(1:/=)/emacs-$(EMACS_VERSION) distclean
	cd $(1:/=)/emacs-$(EMACS_VERSION) && ./configure --prefix=/usr/local $(2)
	$(MAKE) -C $(1:/=)/emacs-$(EMACS_VERSION) -j`nproc`
endef

# Params: $(1) build dir, $(2) executable file, $(3) output file name
define make_shlibdeps
	mkdir -p $(1:/=)/debian && touch $(1:/=)/debian/control
	cd $(1) && dpkg-shlibdeps -O --ignore-missing-info -e $(2) > $(3) || { rm -f $(3); exit 1; }
	sed -i -e 's/^shlibs:Depends=//' $(1:/=)/$(3)
	rm -f $(1:/=)/debian/control
	rmdir $(1:/=)/debian
endef

$(BUILDDIR) $(OBJDIR):
	mkdir -p $@

$(BUILDDIR)/%/build.unpacked: $(DOWNLOAD_FILE) | $(BUILDDIR)
	mkdir -p $(BUILDDIR)/$*
	rm -rf $(@D)/emacs-$(EMACS_VERSION)
	tar -C $(@D) -xvf $(DOWNLOAD_FILE)
	touch $@

$(BUILDDIR)/pgtk/build.compiled: $(BUILDDIR)/pgtk/build.unpacked
	$(call configure_and_build,$(@D),--with-pgtk --with-tree-sitter)
	touch $@
$(BUILDDIR)/tty/build.compiled: $(BUILDDIR)/tty/build.unpacked
	$(call configure_and_build,$(@D),--with-x=no --without-gsettings --with-tree-sitter)
	touch $@
$(BUILDDIR)/x11/build.compiled: $(BUILDDIR)/x11/build.unpacked
	$(call configure_and_build,$(@D),--with-x=yes --with-x-toolkit=gtk3 --with-cairo --with-tree-sitter)
	touch $@

$(BUILDDIR)/%/build.installed: $(BUILDDIR)/%/build.compiled
	$(MAKE) -C $(@D)/emacs-$(EMACS_VERSION) prefix=$(abspath $(@D)/install/usr/local) install-strip
	touch $@

$(BUILDDIR)/%/build.shlibdeps: $(BUILDDIR)/%/build.installed
	$(call make_shlibdeps,$(dir $@),install/usr/local/bin/emacs,build.shlibdeps)

$(BUILDDIR)/%/install/DEBIAN/changelog: debian/changelog_template
	mkdir -p $(dir $@)
	sed -e "s#%{build.variant}#$*#" \
        -e "s#%{build.date}#`LANG=C date -R`#" \
        -e "s#%{build.version}#$(DEB_VER)#" $< > $@

$(BUILDDIR)/%/install/DEBIAN/control: debian/control_template_% $(BUILDDIR)/%/build.shlibdeps
	mkdir -p $(dir $@)
	sed -e "s#%{build.shlibdeps}#`cat $(BUILDDIR)/$*/build.shlibdeps`#" \
        -e "s#%{build.variant}#$*#" \
        -e "s#%{build.date}#`LANG=C date -R`#" \
        -e "s#%{build.version}#$(DEB_VER)#" $< > $@

$(OBJDIR)/emacs-pgtk_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb: $(BUILDDIR)/pgtk/build.installed $(BUILDDIR)/pgtk/build.shlibdeps $(BUILDDIR)/pgtk/install/DEBIAN/control $(BUILDDIR)/pgtk/install/DEBIAN/changelog | $(OBJDIR)
	fakeroot dpkg-deb -b $(BUILDDIR)/pgtk/install $@

$(OBJDIR)/emacs-tty_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb: $(BUILDDIR)/tty/build.installed $(BUILDDIR)/tty/build.shlibdeps $(BUILDDIR)/tty/install/DEBIAN/control $(BUILDDIR)/tty/install/DEBIAN/changelog | $(OBJDIR)
	fakeroot dpkg-deb -b $(BUILDDIR)/tty/install $@

$(OBJDIR)/emacs-x11_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb: $(BUILDDIR)/x11/build.installed $(BUILDDIR)/x11/build.shlibdeps $(BUILDDIR)/x11/install/DEBIAN/control $(BUILDDIR)/x11/install/DEBIAN/changelog | $(OBJDIR)
	fakeroot dpkg-deb -b $(BUILDDIR)/x11/install $@

# Emacs variants main targets
emacs-pgtk: $(OBJDIR)/emacs-pgtk_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb

emacs-tty: $(OBJDIR)/emacs-tty_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb

emacs-x11: $(OBJDIR)/emacs-x11_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb


# Tree sitter package
TS_SONAME_MAJOR ::= $(word 1,$(subst ., ,$(TS_VERSION)))
TS_SONAME_MINOR ::= $(word 2,$(subst ., ,$(TS_VERSION)))
TS_DEB_FILENAME ::= libtree-sitter$(TS_SONAME_MAJOR).$(TS_SONAME_MINOR)_$(TS_VERSION)-1_$(DEB_ARCH).deb

tree-sitter-$(TS_VERSION).tar.gz:
	wget -O $@ "https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v$(TS_VERSION).tar.gz"

$(BUILDDIR)/tree-sitter/build.installed: tree-sitter-$(TS_VERSION).tar.gz | $(BUILDDIR)
	rm -rf $(BUILDDIR)/tree-sitter && mkdir $(BUILDDIR)/tree-sitter
	tar -C $(BUILDDIR)/tree-sitter -xvf tree-sitter-$(TS_VERSION).tar.gz
	$(MAKE) -C $(BUILDDIR)/tree-sitter/tree-sitter-$(TS_VERSION) install PREFIX=$(abspath $(BUILDDIR)/tree-sitter/install/usr/local)
	sed -i -e 's#^prefix=.*#prefix=/usr/local#' $(BUILDDIR)/tree-sitter/install/usr/local/lib/pkgconfig/tree-sitter.pc
	touch $@

$(OBJDIR)/$(TS_DEB_FILENAME): $(BUILDDIR)/tree-sitter/build.installed | $(OBJDIR)
	$(call make_shlibdeps,$(BUILDDIR)/tree-sitter,install/usr/local/lib/libtree-sitter.so,build.shlibdeps)
	mkdir -p $(BUILDDIR)/tree-sitter/install/DEBIAN
	printf 'activate-noawait ldconfig\n' > $(BUILDDIR)/tree-sitter/install/DEBIAN/triggers
	printf "libtree-sitter %d.%d libtree-sitter%d.%d (>= %d.%d)\n" $(TS_SONAME_MAJOR) $(TS_SONAME_MINOR) \
                                                                   $(TS_SONAME_MAJOR) $(TS_SONAME_MINOR) \
                                                                   $(TS_SONAME_MAJOR) $(TS_SONAME_MINOR) > $(BUILDDIR)/tree-sitter/install/DEBIAN/shlibs
	sed -e "s#%{build.shlibdeps}#`cat $(BUILDDIR)/tree-sitter/build.shlibdeps)`#" \
        -e "s#%{build.soname_major}#$(TS_SONAME_MAJOR)#" \
        -e "s#%{build.soname_minor}#$(TS_SONAME_MINOR)#" \
        -e "s#%{build.version}#$(TS_VERSION)-1#" \
        debian/control_template_libtree-sitter > $(BUILDDIR)/tree-sitter/install/DEBIAN/control

	fakeroot dpkg-deb -b $(BUILDDIR)/tree-sitter/install $@

tree-sitter: $(OBJDIR)/$(TS_DEB_FILENAME)
# End tree sitter

clean:
	rm -rf build/ target/

distclean: clean
	rm -f emacs_*.orig.tar.* tree-sitter*.tar.gz

.PHONY: all clean distclean tree-sitter emacs-pgtk emacs-tty emacs-x11
