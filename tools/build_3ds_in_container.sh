#!/bin/sh
# Build The Choicer Voicer with the official devkitARM image.
# Do not run dkp-pacman here: the image already carries the SDK, and refreshing
# package databases can fail when pkg.devkitpro.org returns HTTP 403.
set -eu

: "${DEVKITPRO:=/opt/devkitpro}"
: "${DEVKITARM:=$DEVKITPRO/devkitARM}"
export DEVKITPRO DEVKITARM

cd /work/3ds_port
[ -f "$DEVKITARM/3ds_rules" ] || {
    echo "ERROR: devkitARM rules missing: $DEVKITARM/3ds_rules" >&2
    exit 1
}
[ -x "$DEVKITARM/bin/arm-none-eabi-gcc" ] || {
    echo "ERROR: ARM compiler missing: $DEVKITARM/bin/arm-none-eabi-gcc" >&2
    exit 1
}
[ -f "$DEVKITPRO/3dsvars.sh" ] || {
    echo "ERROR: devkitPro 3DS variables file missing: $DEVKITPRO/3dsvars.sh" >&2
    exit 1
}
[ -d /work/3ds_port/romfs/tcv ] || {
    echo "ERROR: runtime RomFS was not prepared at /work/3ds_port/romfs/tcv" >&2
    echo "Run tools/prepare_3ds_assets.py before building; the app embeds its default art, audio and packs." >&2
    exit 1
}

echo "Using DEVKITPRO=$DEVKITPRO"
echo "Using DEVKITARM=$DEVKITARM"

find_zlib_header() {
    find "$DEVKITPRO/portlibs/3ds" -type f -name zlib.h -print -quit 2>/dev/null || true
}
find_zlib_archive() {
    find "$DEVKITPRO/portlibs/3ds" -type f -name libz.a -print -quit 2>/dev/null || true
}
ZLIB_HEADER="$(find_zlib_header)"
ZLIB_ARCHIVE="$(find_zlib_archive)"

if [ -z "$ZLIB_HEADER" ] || [ -z "$ZLIB_ARCHIVE" ]; then
    echo "3DS zlib portlib was not present in the image; compiling pinned zlib v1.3.1 source as fallback."
    ZLIB_SOURCE=/work/.build-deps/zlib-src
    [ -f "$ZLIB_SOURCE/configure" ] || {
        echo "ERROR: zlib fallback source missing at $ZLIB_SOURCE/configure" >&2
        exit 1
    }
    cd "$ZLIB_SOURCE"
    # Follow devkitPro's own 3DS portlib build recipe (no package database used).
    . "$DEVKITPRO/3dsvars.sh"
    CHOST=arm-none-eabi ./configure --prefix="$DEVKITPRO/portlibs/3ds" --static
    make -j2 libz.a
    make install
    cd /work/3ds_port
    ZLIB_HEADER="$(find_zlib_header)"
    ZLIB_ARCHIVE="$(find_zlib_archive)"
fi

[ -n "$ZLIB_HEADER" ] && [ -f "$ZLIB_HEADER" ] || {
    echo "ERROR: zlib.h was not found under $DEVKITPRO/portlibs/3ds after fallback." >&2
    exit 1
}
[ -n "$ZLIB_ARCHIVE" ] && [ -f "$ZLIB_ARCHIVE" ] || {
    echo "ERROR: libz.a was not found under $DEVKITPRO/portlibs/3ds after fallback." >&2
    exit 1
}
ZLIB_INCLUDE="$(dirname "$ZLIB_HEADER")"
ZLIB_LIBRARY="$(dirname "$ZLIB_ARCHIVE")"
export ZLIB_INCLUDE ZLIB_LIBRARY
echo "Using zlib header: $ZLIB_HEADER"
echo "Using zlib library: $ZLIB_ARCHIVE"

# Probe both header availability and the exact symbol used by video decoding.
printf '#include <zlib.h>\nint main(void) { const unsigned char in[1] = {0}; unsigned char out[32]; uLongf n = sizeof(out); return uncompress(out, &n, in, sizeof(in)); }\n' > /tmp/tcv_zlib_probe.c
"$DEVKITARM/bin/arm-none-eabi-gcc" \
    -march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft \
    -I"$ZLIB_INCLUDE" -c /tmp/tcv_zlib_probe.c -o /tmp/tcv_zlib_probe.o
if command -v "$DEVKITARM/bin/arm-none-eabi-nm" >/dev/null 2>&1; then
    "$DEVKITARM/bin/arm-none-eabi-nm" -g "$ZLIB_ARCHIVE" | grep -Eq '[[:space:]]T[[:space:]]+uncompress$' || {
        echo "ERROR: libz.a does not export the uncompress symbol" >&2
        exit 1
    }
fi

echo "zlib compile probe passed; package database refresh skipped."
make clean
make -j2 V=1 ZLIB_INCLUDE="$ZLIB_INCLUDE" ZLIB_LIBRARY="$ZLIB_LIBRARY"
