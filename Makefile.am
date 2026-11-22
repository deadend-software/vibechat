ACLOCAL_AMFLAGS = -I m4

SUBDIRS = \
    vibe-hexchat/plugins \
    vibe-hexchat/vibechat/hexchat/po \
    vibe-hexchat/vibechat/hexchat/data

# Include directories
AM_CPPFLAGS = \
    -I$(top_srcdir) \
    -I$(top_builddir) \
    -I$(top_srcdir)/vibe-hexchat/vibechat/hexchat \
    -I$(top_srcdir)/vibe-hexchat/vibechat/hexchat/src/common \
    -I$(top_srcdir)/vibe-hexchat/vibechat/hexchat/src/common/dbus \
    -I$(top_srcdir)/vibe-hexchat/vibechat/hexchat/src/fe-gtk \
    -I$(top_srcdir)/vibe-hexchat/plugins \
    $(GLIB_CFLAGS) \
    $(GTK_CFLAGS) \
    $(OPENSSL_CFLAGS) \
    $(LIBCANBERRA_CFLAGS) \
    $(DBUS_CFLAGS) \
    $(ENCHANT_CFLAGS) \
    $(WARN_CFLAGS)

AM_OBJCFLAGS = $(AM_CPPFLAGS) -fobjc-arc

# Convenience library for common IRC logic
noinst_LTLIBRARIES = libhexchatcommon.la

libhexchatcommon_la_SOURCES = \
    vibe-hexchat/vibechat/hexchat/src/common/cfgfiles.c \
    vibe-hexchat/vibechat/hexchat/src/common/chanopt.c \
    vibe-hexchat/vibechat/hexchat/src/common/ctcp.c \
    vibe-hexchat/vibechat/hexchat/src/common/dcc.c \
    vibe-hexchat/vibechat/hexchat/src/common/hexchat.c \
    vibe-hexchat/vibechat/hexchat/src/common/history.c \
    vibe-hexchat/vibechat/hexchat/src/common/ignore.c \
    vibe-hexchat/vibechat/hexchat/src/common/inbound.c \
    vibe-hexchat/vibechat/hexchat/src/common/marshal.c \
    vibe-hexchat/vibechat/hexchat/src/common/modes.c \
    vibe-hexchat/vibechat/hexchat/src/common/network.c \
    vibe-hexchat/vibechat/hexchat/src/common/notify.c \
    vibe-hexchat/vibechat/hexchat/src/common/outbound.c \
    vibe-hexchat/vibechat/hexchat/src/common/plugin.c \
    vibe-hexchat/vibechat/hexchat/src/common/plugin-identd.c \
    vibe-hexchat/vibechat/hexchat/src/common/plugin-timer.c \
    vibe-hexchat/vibechat/hexchat/src/common/proto-irc.c \
    vibe-hexchat/vibechat/hexchat/src/common/scram.c \
    vibe-hexchat/vibechat/hexchat/src/common/server.c \
    vibe-hexchat/vibechat/hexchat/src/common/servlist.c \
    vibe-hexchat/vibechat/hexchat/src/common/text.c \
    vibe-hexchat/vibechat/hexchat/src/common/tree.c \
    vibe-hexchat/vibechat/hexchat/src/common/url.c \
    vibe-hexchat/vibechat/hexchat/src/common/userlist.c \
    vibe-hexchat/vibechat/hexchat/src/common/util.c

if ENABLE_OPENSSL
libhexchatcommon_la_SOURCES += vibe-hexchat/vibechat/hexchat/src/common/ssl.c
endif

if ENABLE_DBUS
libhexchatcommon_la_SOURCES += \
    vibe-hexchat/vibechat/hexchat/src/common/dbus/dbus-client.c \
    vibe-hexchat/vibechat/hexchat/src/common/dbus/dbus-plugin.c
endif

# Main executable
bin_PROGRAMS = vibechat

vibechat_SOURCES = \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/ascii.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/banlist.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/chanlist.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/chanview.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/custom-list.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/dccgui.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/editlist.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/fe-gtk.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/fkeys.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/gtkutil.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/ignoregui.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/joind.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/maingui.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/menu.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/notifygui.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/palette.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/pixmaps.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/plugin-notification.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/plugin-tray.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/plugingui.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/rawlog.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/resources.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/servlistgui.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/setup.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/sexy-iso-codes.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/sexy-spell-entry.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/textgui.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/urlgrab.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/userlistgui.c \
    vibe-hexchat/vibechat/hexchat/src/fe-gtk/xtext.c

if OS_DARWIN
vibechat_SOURCES += vibe-hexchat/vibechat/hexchat/src/fe-gtk/notifications/notification-osx.m
endif

vibechat_LDFLAGS = $(OS_LDFLAGS)
vibechat_LDADD = \
    libhexchatcommon.la \
    $(GTK_LIBS) \
    $(GLIB_LIBS) \
    $(OPENSSL_LIBS) \
    $(LIBCANBERRA_LIBS) \
    $(DBUS_LIBS) \
    $(ENCHANT_LIBS) \
    $(INTLLIBS) \
    $(OS_LIBS)

# Install public plugin header
include_HEADERS = vibe-hexchat/vibechat/hexchat/src/common/hexchat-plugin.h

# Symlink hexchat -> vibechat
all-local:
	$(AM_V_at)$(LN_S) -f vibechat$(EXEEXT) hexchat$(EXEEXT)

clean-local:
	-rm -f hexchat$(EXEEXT)

install-exec-hook:
	cd $(DESTDIR)$(bindir) && rm -f hexchat$(EXEEXT) && $(LN_S) vibechat$(EXEEXT) hexchat$(EXEEXT)

uninstall-hook:
	rm -f $(DESTDIR)$(bindir)/hexchat$(EXEEXT)
