AC_PREREQ([2.69])
AC_INIT([vibechat], [2.16.2], [https://github.com/deadend-software/vibechat])
AC_CONFIG_SRCDIR([vibe-hexchat/vibechat/hexchat/src/common/hexchat.c])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([build-aux])

AM_INIT_AUTOMAKE([foreign subdir-objects -Wall -Wno-portability tar-pax])
AM_MAINTAINER_MODE([enable])
AM_SILENT_RULES([yes])

# OS detection
AC_CANONICAL_HOST

os_darwin=no
os_linux=no
os_windows=no

case "$host_os" in
  darwin*)
    os_darwin=yes
    ;;
  linux*)
    os_linux=yes
    ;;
  *mingw*|*msys*|*cygwin*|*windows*)
    os_windows=yes
    ;;
esac

AM_CONDITIONAL([OS_DARWIN], [test "x$os_darwin" = "xyes"])
AM_CONDITIONAL([OS_LINUX], [test "x$os_linux" = "xyes"])
AM_CONDITIONAL([OS_WINDOWS], [test "x$os_windows" = "xyes"])

# Environment setup for macOS / Homebrew
if test "x$os_darwin" = "xyes"; then
    for prefix in /opt/homebrew /usr/local; do
        if test -d "$prefix"; then
            PKG_CONFIG_PATH="$prefix/lib/pkgconfig:$prefix/share/pkgconfig:$prefix/opt/openssl@4/lib/pkgconfig:$prefix/opt/openssl@3/lib/pkgconfig:$prefix/opt/openssl/lib/pkgconfig:$prefix/opt/libcanberra/lib/pkgconfig:$prefix/opt/dbus-glib/lib/pkgconfig:$prefix/opt/luajit/lib/pkgconfig:$prefix/opt/enchant/lib/pkgconfig:$prefix/opt/gettext/lib/pkgconfig:$PKG_CONFIG_PATH"
            PATH="$prefix/bin:$PATH"
            break
        fi
    done
    export PKG_CONFIG_PATH
    export PATH
fi

# Checks for programs
AC_PROG_CC
AC_PROG_INSTALL
AM_PROG_AR
LT_INIT([disable-static])
AC_PROG_LN_S

# Objective-C check
if test "x$os_darwin" = "xyes"; then
    AC_PROG_OBJC
    OBJCFLAGS="$OBJCFLAGS -fobjc-arc"
    OS_LDFLAGS="-Wl,-sectcreate,__TEXT,__info_plist,\$(top_srcdir)/vibe-hexchat/vibechat/hexchat/osx/Info.plist"
    OS_LIBS="-framework Cocoa -framework CoreFoundation -framework ApplicationServices"
else
    OS_LDFLAGS=""
    OS_LIBS=""
fi
AC_SUBST([OS_LDFLAGS])
AC_SUBST([OS_LIBS])

PKG_PROG_PKG_CONFIG

# Mandatory packages: GLib & GTK+
PKG_CHECK_MODULES([GLIB], [glib-2.0 >= 2.36.0 gio-2.0 gmodule-2.0 gobject-2.0])
PKG_CHECK_MODULES([GTK], [gtk+-2.0 >= 2.24.0 pango >= 1.0 pangocairo >= 1.0 cairo >= 1.0 gdk-pixbuf-2.0 >= 2.0 atk >= 1.0])

# OpenSSL
AC_ARG_ENABLE([openssl],
    [AS_HELP_STRING([--disable-openssl], [Disable OpenSSL TLS support])],
    [enable_openssl=$enableval],
    [enable_openssl=auto])

have_openssl=no
if test "x$enable_openssl" != "xno"; then
    PKG_CHECK_MODULES([OPENSSL], [openssl >= 0.9.8], [have_openssl=yes], [have_openssl=no])
    if test "x$have_openssl" = "xyes"; then
        AC_DEFINE([USE_OPENSSL], [1], [Define to 1 if OpenSSL is supported])
        save_LIBS="$LIBS"
        LIBS="$LIBS $OPENSSL_LIBS"
        save_CFLAGS="$CFLAGS"
        CFLAGS="$CFLAGS $OPENSSL_CFLAGS"
        AC_CHECK_FUNCS([X509_get_signature_nid SSL_CTX_get_ssl_method DH_set0_pqg DH_get0_key DH_set0_key ERR_remove_thread_state ASN1_STRING_get0_data])
        AC_MSG_CHECKING([whether OpenSSL is 1.1.0 or newer])
        AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include <openssl/opensslv.h>]], [[
#if OPENSSL_VERSION_NUMBER < 0x10100000L
#error OpenSSL is older than 1.1.0
#endif
        ]])], [
            AC_MSG_RESULT([yes])
            AC_DEFINE([HAVE_ERR_REMOVE_THREAD_STATE], [1], [Define to 1 if OpenSSL is 1.1.0+ or has ERR_remove_thread_state])
        ], [
            AC_MSG_RESULT([no])
        ])
        LIBS="$save_LIBS"
        CFLAGS="$save_CFLAGS"
    elif test "x$enable_openssl" = "xyes"; then
        AC_MSG_ERROR([OpenSSL requested but not found])
    fi
fi
AM_CONDITIONAL([ENABLE_OPENSSL], [test "x$have_openssl" = "xyes"])

# Libcanberra (sound events)
AC_ARG_ENABLE([libcanberra],
    [AS_HELP_STRING([--disable-libcanberra], [Disable libcanberra sound event support])],
    [enable_libcanberra=$enableval],
    [enable_libcanberra=auto])

have_libcanberra=no
if test "x$enable_libcanberra" != "xno"; then
    PKG_CHECK_MODULES([LIBCANBERRA], [libcanberra >= 0.22], [have_libcanberra=yes], [have_libcanberra=no])
    if test "x$have_libcanberra" = "xyes"; then
        AC_DEFINE([USE_LIBCANBERRA], [1], [Define to 1 if libcanberra is supported])
    elif test "x$enable_libcanberra" = "xyes"; then
        AC_MSG_ERROR([libcanberra requested but not found])
    fi
fi
AM_CONDITIONAL([ENABLE_LIBCANBERRA], [test "x$have_libcanberra" = "xyes"])

# D-Bus IPC
AC_ARG_ENABLE([dbus],
    [AS_HELP_STRING([--disable-dbus], [Disable D-Bus support])],
    [enable_dbus=$enableval],
    [enable_dbus=auto])

have_dbus=no
if test "x$enable_dbus" != "xno"; then
    PKG_CHECK_MODULES([DBUS], [dbus-1 >= 1.0 dbus-glib-1 >= 0.90], [have_dbus=yes], [have_dbus=no])
    if test "x$have_dbus" = "xyes"; then
        AC_DEFINE([USE_DBUS], [1], [Define to 1 if D-Bus is supported])
        AC_DEFINE([DBUS_SERVICE], ["io.github.Hexchat"], [D-Bus service name])
    elif test "x$enable_dbus" = "xyes"; then
        AC_MSG_ERROR([D-Bus requested but not found])
    fi
fi
AM_CONDITIONAL([ENABLE_DBUS], [test "x$have_dbus" = "xyes"])

# Desktop exec command based on dbus
if test "x$have_dbus" = "xyes"; then
    exec_command="vibechat --existing %U"
else
    exec_command="vibechat %U"
fi
AC_SUBST([exec_command])

# Spell Checking (Enchant)
AC_ARG_ENABLE([spell],
    [AS_HELP_STRING([--disable-spell], [Disable spell checking via Enchant])],
    [enable_spell=$enableval],
    [enable_spell=auto])

have_enchant=no
if test "x$enable_spell" != "xno"; then
    PKG_CHECK_MODULES([ENCHANT], [enchant-2], [have_enchant=yes],
        [PKG_CHECK_MODULES([ENCHANT], [enchant >= 1.4.0], [have_enchant=yes], [have_enchant=no])])
    if test "x$have_enchant" = "xyes"; then
        AC_DEFINE([USE_ENCHANT], [1], [Define to 1 if Enchant spell checking is enabled])
    elif test "x$enable_spell" = "xyes"; then
        AC_MSG_ERROR([Enchant requested but not found])
    fi
fi
AM_CONDITIONAL([ENABLE_ENCHANT], [test "x$have_enchant" = "xyes"])

# ISO Codes
PKG_CHECK_MODULES([ISO_CODES], [iso-codes], [have_iso_codes=yes], [have_iso_codes=no])
if test "x$have_iso_codes" = "xyes"; then
    AC_DEFINE([HAVE_ISO_CODES], [1], [Define to 1 if iso-codes is available])
    ISO_CODES_PREFIX=`$PKG_CONFIG --variable=prefix iso-codes`
    AC_DEFINE_UNQUOTED([ISO_CODES_PREFIX], ["$ISO_CODES_PREFIX"], [Prefix where iso-codes are installed])
    AC_DEFINE_UNQUOTED([ISO_CODES_LOCALEDIR], ["$ISO_CODES_PREFIX/share/locale"], [Locale directory for iso-codes])
fi

# Plugin support
AC_ARG_ENABLE([plugin],
    [AS_HELP_STRING([--disable-plugin], [Disable dynamic plugin loading])],
    [enable_plugin=$enableval],
    [enable_plugin=yes])

if test "x$enable_plugin" = "xyes"; then
    AC_DEFINE([USE_PLUGIN], [1], [Define to 1 if dynamic plugin loading is enabled])
fi
AM_CONDITIONAL([ENABLE_PLUGIN], [test "x$enable_plugin" = "xyes"])

# Plugins: Checksum
AC_ARG_ENABLE([checksum],
    [AS_HELP_STRING([--disable-checksum], [Disable checksum plugin])],
    [enable_checksum=$enableval],
    [enable_checksum=yes])
AM_CONDITIONAL([ENABLE_CHECKSUM], [test "x$enable_checksum" = "xyes" && test "x$enable_plugin" = "xyes"])

# Plugins: Fishlim
AC_ARG_ENABLE([fishlim],
    [AS_HELP_STRING([--disable-fishlim], [Disable fishlim encryption plugin])],
    [enable_fishlim=$enableval],
    [enable_fishlim=auto])
have_fishlim=no
if test "x$enable_fishlim" != "xno" && test "x$enable_plugin" = "xyes"; then
    if test "x$have_openssl" = "xyes"; then
        have_fishlim=yes
    elif test "x$enable_fishlim" = "xyes"; then
        AC_MSG_ERROR([fishlim plugin requires OpenSSL])
    fi
fi
AM_CONDITIONAL([ENABLE_FISHLIM], [test "x$have_fishlim" = "xyes"])

# Plugins: Sysinfo
AC_ARG_ENABLE([sysinfo],
    [AS_HELP_STRING([--disable-sysinfo], [Disable sysinfo plugin])],
    [enable_sysinfo=$enableval],
    [enable_sysinfo=yes])
AM_CONDITIONAL([ENABLE_SYSINFO], [test "x$enable_sysinfo" = "xyes" && test "x$enable_plugin" = "xyes"])

# Plugins: Lua
AC_ARG_ENABLE([lua],
    [AS_HELP_STRING([--disable-lua], [Disable Lua plugin])],
    [enable_lua=$enableval],
    [enable_lua=auto])
have_lua=no
if test "x$enable_lua" != "xno" && test "x$enable_plugin" = "xyes"; then
    PKG_CHECK_MODULES([LUA], [luajit >= 2.0], [have_lua=yes],
        [PKG_CHECK_MODULES([LUA], [lua-5.1], [have_lua=yes],
            [PKG_CHECK_MODULES([LUA], [lua5.1], [have_lua=yes],
                [PKG_CHECK_MODULES([LUA], [lua >= 5.1], [have_lua=yes], [have_lua=no])])])])
    if test "x$have_lua" = "xno" && test "x$enable_lua" = "xyes"; then
        AC_MSG_ERROR([Lua requested but not found])
    fi
fi
AM_CONDITIONAL([ENABLE_LUA], [test "x$have_lua" = "xyes"])

# Plugins: Perl
AC_ARG_ENABLE([perl],
    [AS_HELP_STRING([--disable-perl], [Disable Perl plugin])],
    [enable_perl=$enableval],
    [enable_perl=auto])
have_perl=no
if test "x$enable_perl" != "xno" && test "x$enable_plugin" = "xyes"; then
    AC_PATH_PROG([PERL], [perl])
    if test -n "$PERL"; then
        PERL_CFLAGS=`$PERL -MExtUtils::Embed -e ccopts 2>/dev/null`
        PERL_LDFLAGS=`$PERL -MExtUtils::Embed -e ldopts 2>/dev/null`
        if test -n "$PERL_CFLAGS"; then
            have_perl=yes
            AC_SUBST([PERL_CFLAGS])
            AC_SUBST([PERL_LDFLAGS])
        fi
    fi
    if test "x$have_perl" = "xno" && test "x$enable_perl" = "xyes"; then
        AC_MSG_ERROR([Perl requested but ExtUtils::Embed failed])
    fi
fi
AM_CONDITIONAL([ENABLE_PERL], [test "x$have_perl" = "xyes"])

# Directories
hexchatplugindir='${libdir}/hexchat/plugins'
AC_SUBST([hexchatplugindir])
hexchatsharedir='${datadir}/hexchat'
AC_SUBST([hexchatsharedir])

eval "eval_libdir=\"$libdir\""
eval "eval_datadir=\"$datadir\""
eval "eval_localedir=\"$localedir\""
eval "eval_plugindir=\"$hexchatplugindir\""
eval "eval_sharedir=\"$hexchatsharedir\""

AC_DEFINE_UNQUOTED([HEXCHATLIBDIR], ["$eval_plugindir"], [Plugin directory])
AC_DEFINE_UNQUOTED([HEXCHATSHAREDIR], ["$eval_sharedir"], [Shared data directory])
AC_DEFINE_UNQUOTED([LOCALEDIR], ["$eval_localedir"], [Locale directory])

# Gettext / NLS
AC_PATH_PROG([MSGFMT], [msgfmt])
AM_CONDITIONAL([HAVE_MSGFMT], [test -n "$MSGFMT"])
AC_CHECK_LIB([intl], [gettext], [INTLLIBS="-lintl"], [INTLLIBS=""])
AC_SUBST([INTLLIBS])
AC_DEFINE([ENABLE_NLS], [1], [Define to 1 if translation is enabled])
AC_DEFINE([GETTEXT_PACKAGE], ["hexchat"], [Gettext package name])

# Core project defines
AC_DEFINE([G_LOG_DOMAIN], ["hexchat"], [GLib log domain])
AC_DEFINE([GLIB_VERSION_MAX_ALLOWED], [GLIB_VERSION_2_36], [GLib max version])
AC_DEFINE([GLIB_VERSION_MIN_REQUIRED], [GLIB_VERSION_2_36], [GLib min version])

# Header & function checks
AC_CHECK_HEADERS([strings.h sys/wait.h unistd.h])
AC_CHECK_FUNCS([memrchr])

# Compiler warning flags
WARN_CFLAGS="-Wno-pointer-sign -Wno-deprecated-declarations -Wno-strict-prototypes -Wno-documentation -Wno-ambiguous-macro"
AC_SUBST([WARN_CFLAGS])

AC_CONFIG_FILES([
  Makefile
  vibe-hexchat/plugins/Makefile
  vibe-hexchat/vibechat/hexchat/po/Makefile
  vibe-hexchat/vibechat/hexchat/data/Makefile
  vibe-hexchat/vibechat/hexchat/data/pkgconfig/hexchat-plugin.pc:vibe-hexchat/vibechat/hexchat/data/pkgconfig/hexchat-plugin.pc.in
  vibe-hexchat/vibechat/hexchat/data/man/hexchat.1:vibe-hexchat/vibechat/hexchat/data/man/hexchat.1.in
  vibe-hexchat/vibechat/hexchat/data/misc/io.github.Hexchat.desktop:vibe-hexchat/vibechat/hexchat/data/misc/io.github.Hexchat.desktop.in.in
])

AC_OUTPUT

echo
echo "--- VibeChat Autotools Configuration ---"
echo "  Target system:        $host_os"
echo "  Compiler:             $CC $CFLAGS"
echo "  Prefix:               $prefix"
echo "  OpenSSL support:      $have_openssl"
echo "  Libcanberra support:  $have_libcanberra"
echo "  D-Bus support:        $have_dbus"
echo "  Enchant spell check:  $have_enchant"
echo "  ISO codes:            $have_iso_codes"
echo "  Plugins enabled:      $enable_plugin"
echo "    Checksum:           $enable_checksum"
echo "    Fishlim:            $have_fishlim"
echo "    Sysinfo:            $enable_sysinfo"
echo "    Lua:                $have_lua"
echo "    Perl:               $have_perl"
echo "----------------------------------------"
echo
