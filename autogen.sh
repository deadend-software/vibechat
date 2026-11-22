#!/bin/sh
set -e

srcdir=$(cd "$(dirname "$0")" && pwd)
cd "$srcdir"

# Detect macOS and ensure Homebrew toolchain & pkgconfig are in path
if [ "$(uname -s)" = "Darwin" ]; then
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    elif [ -d "/usr/local/bin" ]; then
        export PATH="/usr/local/bin:$PATH"
    fi
    BREW_PREFIX="$(brew --prefix 2>/dev/null || echo '/opt/homebrew')"
    if [ -d "$BREW_PREFIX" ]; then
        export PKG_CONFIG_PATH="$BREW_PREFIX/lib/pkgconfig:$BREW_PREFIX/share/pkgconfig:$BREW_PREFIX/opt/openssl@4/lib/pkgconfig:$BREW_PREFIX/opt/openssl@3/lib/pkgconfig:$BREW_PREFIX/opt/openssl/lib/pkgconfig:$BREW_PREFIX/opt/libcanberra/lib/pkgconfig:$BREW_PREFIX/opt/dbus-glib/lib/pkgconfig:$BREW_PREFIX/opt/luajit/lib/pkgconfig:$BREW_PREFIX/opt/enchant/lib/pkgconfig:$BREW_PREFIX/opt/gettext/lib/pkgconfig:$PKG_CONFIG_PATH"
    fi
fi

# Ensure glibtoolize / libtoolize is available
if command -v glibtoolize >/dev/null 2>&1; then
    LIBTOOLIZE=glibtoolize
elif command -v libtoolize >/dev/null 2>&1; then
    LIBTOOLIZE=libtoolize
else
    echo "Error: neither libtoolize nor glibtoolize found." >&2
    exit 1
fi

mkdir -p m4 build-aux

echo "==> Running $LIBTOOLIZE..."
$LIBTOOLIZE --copy --force

echo "==> Running autoreconf..."
autoreconf -vfi

echo
echo "==> Autotools build system generated successfully."
echo "You can now run:"
echo "    ./configure"
echo "    make"
echo

if [ -z "$NOCONFIGURE" ]; then
    echo "==> Running ./configure $@"
    ./configure "$@"
fi
