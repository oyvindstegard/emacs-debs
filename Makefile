# Download, build and make deb packages of Emacs on Ubuntu.
# TODO add libtree-sitter build
# TODO add x11 build

EMACS_VERSION ::= 30.1
TREE_SITTER_VERSION ::= 0.25.4

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

# Params: $(1) variant build dir, $(2) extra config flags
define configure_and_build
	$(MAKE) -C $(1:/=)/emacs-$(EMACS_VERSION) distclean
	cd $(1:/=)/emacs-$(EMACS_VERSION) && ./configure --prefix=/usr/local $(2)
	$(MAKE) -C $(1:/=)/emacs-$(EMACS_VERSION) -j`nproc`
endef

# Params: $(1) variant build dir, $(2) install prefix dir
define install
	$(MAKE) -C $(1:/=)/emacs-$(EMACS_VERSION) prefix=$(abspath $(2)) install-strip
endef

# Params: $(1) variant build dir, $(2) executable file, $(3) output file name
define make_shlibdeps
	mkdir -p $(1:/=)/debian && touch $(1:/=)/debian/control
	cd $(1) && dpkg-shlibdeps -O --ignore-missing-info -e $(2) > $(3) || { rm -f $(3); exit 1; }
	sed -i -e 's/^shlibs:Depends=//' $(1:/=)/$(3)
	rm -f $(1:/=)/debian/control
	rmdir $(1:/=)/debian
endef

$(BUILDDIR) $(OBJDIR):
	mkdir -p $@

$(BUILDDIR)/%/emacs-$(EMACS_VERSION): $(DOWNLOAD_FILE) | $(BUILDDIR)
	mkdir -p $(BUILDDIR)/$*
	tar -C $(dir $@) -xvf $(DOWNLOAD_FILE)

$(BUILDDIR)/pgtk/build.compiled: | $(BUILDDIR)/pgtk/emacs-$(EMACS_VERSION)
	$(call configure_and_build,$(dir $@),--with-pgtk)
	touch $@
$(BUILDDIR)/tty/build.compiled: | $(BUILDDIR)/tty/emacs-$(EMACS_VERSION)
	$(call configure_and_build,$(dir $@),--with-x=no --without-gsettings)
	touch $@
$(BUILDDIR)/x11/build.compiled: | $(BUILDDIR)/x11/emacs-$(EMACS_VERSION)
	$(call configure_and_build,$(dir $@),--with-x=yes --with-x-toolkit=gtk3 --with-cairo)
	touch $@

$(BUILDDIR)/pgtk/build.installed: $(BUILDDIR)/pgtk/build.compiled
	$(call install,$(dir $@),$(dir $@)/install/usr/local)
	touch $@
$(BUILDDIR)/tty/build.installed: $(BUILDDIR)/tty/build.compiled
	$(call install,$(dir $@),$(patsubst %/,%,$(dir $@))/install/usr/local)
	touch $@
$(BUILDDIR)/x11/build.installed: $(BUILDDIR)/x11/build.compiled
	$(call install,$(dir $@),$(patsubst %/,%,$(dir $@))/install/usr/local)
	touch $@

$(BUILDDIR)/pgtk/build.shlibdeps: $(BUILDDIR)/pgtk/build.installed $(BUILDDIR)/pgtk/install/usr/local/bin/emacs
	$(call make_shlibdeps,$(dir $@),install/usr/local/bin/emacs,build.shlibdeps)
$(BUILDDIR)/tty/build.shlibdeps: $(BUILDDIR)/tty/build.installed $(BUILDDIR)/tty/install/usr/local/bin/emacs
	$(call make_shlibdeps,$(dir $@),install/usr/local/bin/emacs,build.shlibdeps)
$(BUILDDIR)/x11/build.shlibdeps: $(BUILDDIR)/x11/build.installed $(BUILDDIR)/x11/install/usr/local/bin/emacs
	$(call make_shlibdeps,$(dir $@),install/usr/local/bin/emacs,build.shlibdeps)


$(BUILDDIR)/%/install/DEBIAN/changelog: debian/changelog_template
	 sed -e "s/%{build.version}/$(DEB_VER)/" -e "s/%{build.variant}/$(*)/" -e "s/%{build.changelogdate}/`LANG=C date -R`/" $< > $@

$(BUILDDIR)/pgtk/install/DEBIAN/control: debian/control_template_pgtk $(BUILDDIR)/pgtk/build.shlibdeps
	mkdir -p $(dir $@)
	sed -e "s#%{build.shlibdeps}#`cat $(BUILDDIR)/pgtk/build.shlibdeps`#" -e "s#%{build.version}#$(DEB_VER)#" $< > $@
$(BUILDDIR)/tty/install/DEBIAN/control: debian/control_template_tty $(BUILDDIR)/tty/build.shlibdeps
	mkdir -p $(dir $@)
	sed -e "s#%{build.shlibdeps}#`cat $(BUILDDIR)/tty/build.shlibdeps`#" -e "s#%{build.version}#$(DEB_VER)#" $< > $@
$(BUILDDIR)/x11/install/DEBIAN/control: debian/control_template_x11 $(BUILDDIR)/x11/build.shlibdeps
	mkdir -p $(dir $@)
	sed -e "s#%{build.shlibdeps}#`cat $(BUILDDIR)/x11/build.shlibdeps`#" -e "s#%{build.version}#$(DEB_VER)#" $< > $@

$(OBJDIR)/emacs-pgtk_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb: $(BUILDDIR)/pgtk/build.shlibdeps $(BUILDDIR)/pgtk/install/DEBIAN/control $(BUILDDIR)/pgtk/install/DEBIAN/changelog | $(OBJDIR)
	fakeroot dpkg-deb -b $(BUILDDIR)/pgtk/install $@

$(OBJDIR)/emacs-tty_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb: $(BUILDDIR)/tty/build.shlibdeps $(BUILDDIR)/tty/install/DEBIAN/control $(BUILDDIR)/tty/install/DEBIAN/changelog | $(OBJDIR)
	fakeroot dpkg-deb -b $(BUILDDIR)/tty/install $@

$(OBJDIR)/emacs-x11_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb: $(BUILDDIR)/x11/build.shlibdeps $(BUILDDIR)/x11/install/DEBIAN/control $(BUILDDIR)/x11/install/DEBIAN/changelog | $(OBJDIR)
	fakeroot dpkg-deb -b $(BUILDDIR)/x11/install $@

emacs-pgtk: $(OBJDIR)/emacs-pgtk_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb

emacs-tty: $(OBJDIR)/emacs-tty_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb

emacs-x11: $(OBJDIR)/emacs-x11_$(DEB_VER)$(DISTRO)_$(DEB_ARCH).deb

# Tree sitter
tree-sitter-$(TREE_SITTER_VERSION).tar.gz:
	wget -O $@ "https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v$(TREE_SITTER_VERSION).tar.gz"

$(BUILDDIR)/tree-sitter/build.installed: tree-sitter-$(TREE_SITTER_VERSION).tar.gz | $(BUILDDIR)
	rm -rf $(BUILDDIR)/tree-sitter && mkdir -p $(BUILDDIR)/tree-sitter
	tar -C $(BUILDDIR)/tree-sitter -xvf tree-sitter-$(TREE_SITTER_VERSION).tar.gz
	cd $(BUILDDIR)/tree-sitter/tree-sitter-$(TREE_SITTER_VERSION) && make && make install PREFIX=$(abspath $(BUILDDIR)/tree-sitter/install/usr/local)
	touch $@

$(OBJDIR)/libtree-sitter_$(TREE_SITTER_VERSION)-1_$(DEB_ARCH).deb: $(BUILDDIR)/tree-sitter/build.installed | $(OBJDIR)
	$(call make_shlibdeps,$(BUILDDIR)/tree-sitter,install/usr/local/lib/libtree-sitter.so,build.shlibdeps)
	mkdir -p $(BUILDDIR)/tree-sitter/install/DEBIAN
	printf '#!/bin/sh\n/usr/sbin/ldconfig\n' > $(BUILDDIR)/tree-sitter/install/DEBIAN/postinst
	chmod +x $(BUILDDIR)/tree-sitter/install/DEBIAN/postinst
	sed -e "s#%{build.shlibdeps}#`cat $(BUILDDIR)/tree-sitter/build.shlibdeps`#" -e "s#%{build.version}#$(TREE_SITTER_VERSION)-1#" debian/control_template_libtree-sitter > $(BUILDDIR)/tree-sitter/install/DEBIAN/control
	fakeroot dpkg-deb -b $(BUILDDIR)/tree-sitter/install $@

tree-sitter: $(OBJDIR)/libtree-sitter_$(TREE_SITTER_VERSION)-1_$(DEB_ARCH).deb
# End tree sitter

clean:
	rm -rf build/ target/

distclean: clean
	rm -f emacs_*.orig.tar.* tree-sitter*.tar.gz

.PHONY: all clean distclean tree-sitter emacs-pgtk emacs-tty emacs-x11
