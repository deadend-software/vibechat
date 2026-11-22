EXTRA_DIST = \
    hexchat.gresource.xml \
    icons \
    man/hexchat.1.in \
    misc/io.github.Hexchat.appdata.xml.in \
    misc/io.github.Hexchat.desktop.in.in \
    misc/io.github.Hexchat.ThemeManager.desktop.in \
    misc/io.github.Hexchat.ThemeManager.xml \
    pkgconfig/hexchat-plugin.pc.in

# Pkg-config
pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = pkgconfig/hexchat-plugin.pc

# Man page
man1_MANS = man/hexchat.1

# Desktop file
desktopdir = $(datadir)/applications
desktop_DATA = misc/io.github.Hexchat.desktop

# Icons
icons48dir = $(datadir)/icons/hicolor/48x48/apps
icons48_DATA = icons/hexchat.png icons/vibechat.png

pixmapsdir = $(datadir)/pixmaps
pixmaps_DATA = icons/hexchat.png icons/vibechat.png

install-data-hook:
	$(AM_V_at)$(MKDIR_P) $(DESTDIR)$(mandir)/man1
	$(AM_V_at)(cd $(DESTDIR)$(mandir)/man1 && rm -f vibechat.1 && $(LN_S) hexchat.1 vibechat.1)

uninstall-hook:
	rm -f $(DESTDIR)$(mandir)/man1/vibechat.1
