#!/bin/sh
topdir=$(cd "$(dirname "$0")/.." && pwd)
echo "==> Delegating to project root autogen.sh ($topdir)..."
exec "$topdir/autogen.sh" "$@"
