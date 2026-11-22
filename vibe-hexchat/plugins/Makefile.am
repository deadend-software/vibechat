hexchatplugindir = $(libdir)/hexchat/plugins

AM_CPPFLAGS = \
    -I$(top_srcdir) \
    -I$(top_builddir) \
    -I$(top_srcdir)/vibe-hexchat/vibechat/hexchat \
    -I$(top_srcdir)/vibe-hexchat/vibechat/hexchat/src/common \
    -I$(top_srcdir)/vibe-hexchat/plugins \
    $(GLIB_CFLAGS) \
    $(WARN_CFLAGS)

AM_LDFLAGS = -module -avoid-version

hexchatplugin_LTLIBRARIES =

# Checksum plugin
if ENABLE_CHECKSUM
hexchatplugin_LTLIBRARIES += checksum.la
checksum_la_SOURCES = checksum/checksum.c
checksum_la_LIBADD = $(GLIB_LIBS)
endif

# Fishlim plugin
if ENABLE_FISHLIM
hexchatplugin_LTLIBRARIES += fishlim.la
fishlim_la_SOURCES = \
    fishlim/dh1080.c \
    fishlim/fish.c \
    fishlim/irc.c \
    fishlim/keystore.c \
    fishlim/plugin_hexchat.c \
    fishlim/utils.c
fishlim_la_CPPFLAGS = $(AM_CPPFLAGS) $(OPENSSL_CFLAGS) -I$(srcdir)/fishlim
fishlim_la_LIBADD = $(GLIB_LIBS) $(OPENSSL_LIBS)
endif

# Sysinfo plugin
if ENABLE_SYSINFO
hexchatplugin_LTLIBRARIES += sysinfo.la
sysinfo_la_SOURCES = \
    sysinfo/format.c \
    sysinfo/sysinfo.c \
    sysinfo/shared/df.c

if OS_DARWIN
sysinfo_la_SOURCES += sysinfo/osx/backend.m
sysinfo_la_CPPFLAGS = $(AM_CPPFLAGS) -I$(srcdir)/sysinfo -I$(srcdir)/sysinfo/shared
sysinfo_la_OBJCFLAGS = $(AM_CPPFLAGS) -I$(srcdir)/sysinfo -I$(srcdir)/sysinfo/shared -fobjc-arc
sysinfo_la_LDFLAGS = $(AM_LDFLAGS) -framework Cocoa -framework IOKit
sysinfo_la_LIBADD = $(GLIB_LIBS)
else
sysinfo_la_SOURCES += \
    sysinfo/unix/backend.c \
    sysinfo/unix/match.c \
    sysinfo/unix/parse.c
sysinfo_la_CPPFLAGS = $(AM_CPPFLAGS) -I$(srcdir)/sysinfo -I$(srcdir)/sysinfo/shared -I$(srcdir)/sysinfo/unix
sysinfo_la_LIBADD = $(GLIB_LIBS)
endif
endif

# Lua plugin
if ENABLE_LUA
hexchatplugin_LTLIBRARIES += lua.la
lua_la_SOURCES = lua/lua.c
lua_la_CPPFLAGS = $(AM_CPPFLAGS) $(LUA_CFLAGS)
lua_la_LIBADD = $(GLIB_LIBS) $(LUA_LIBS)
endif

# Perl plugin
if ENABLE_PERL
hexchatplugin_LTLIBRARIES += perl.la
perl_la_SOURCES = perl/perl.c
perl_la_CPPFLAGS = $(AM_CPPFLAGS) -I$(srcdir)/perl $(PERL_CFLAGS) -Wno-compound-token-split-by-macro
perl_la_LDFLAGS = $(AM_LDFLAGS) $(PERL_LDFLAGS)
perl_la_LIBADD = $(GLIB_LIBS) $(PERL_LIBS)
endif

# Unit tests
check_PROGRAMS =
TESTS =

if ENABLE_FISHLIM
check_PROGRAMS += fishlim_tests
TESTS += fishlim_tests

fishlim_tests_SOURCES = \
    fishlim/tests/tests.c \
    fishlim/tests/mock-keystore.c \
    fishlim/fish.c \
    fishlim/utils.c

fishlim_tests_CPPFLAGS = $(AM_CPPFLAGS) $(OPENSSL_CFLAGS) -I$(srcdir)/fishlim
fishlim_tests_LDADD = $(GLIB_LIBS) $(OPENSSL_LIBS)
endif
