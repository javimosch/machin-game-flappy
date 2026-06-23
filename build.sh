#!/usr/bin/env bash
# Build machin-game-flappy. Uses a system raylib if one is installed; otherwise
# fetches raylib's prebuilt *static* release into vendor/ (no root needed) and
# links that. The committed source stays system-style; the vendored path is
# injected into a throwaway copy so flappy.src is never rewritten.
# Requires machin v0.43.0+ (uses the float() builtin).
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"
SRC=flappy.src

have_system_raylib() {
    pkg-config --exists raylib 2>/dev/null && return 0
    [ -f /usr/include/raylib.h ] || [ -f /usr/local/include/raylib.h ]
}

if have_system_raylib; then
    "$MACHIN" encode "$SRC" > flappy.mfl
else
    RL_VER=5.0
    RL_TAR="raylib-${RL_VER}_linux_amd64"
    RL_DIR="vendor/${RL_TAR}"
    if [ ! -f "${RL_DIR}/lib/libraylib.a" ]; then
        echo "raylib not found system-wide; vendoring the prebuilt static release..."
        mkdir -p vendor
        curl -fsSL "https://github.com/raysan5/raylib/releases/download/${RL_VER}/${RL_TAR}.tar.gz" \
            | tar xz -C vendor
    fi
    INC="$PWD/${RL_DIR}/include"
    LIB="$PWD/${RL_DIR}/lib"
    tmp="$(mktemp)"
    "$MACHIN" encode "$SRC" \
        | sed "s#header \"raylib.h\"#cflags \"-I${INC} -L${LIB}\" header \"raylib.h\"#; s#link \"raylib\"#link \":libraylib.a\"#" \
        > "$tmp"
    mv "$tmp" flappy.mfl
fi

"$MACHIN" build flappy.mfl -o machin-game-flappy
echo "built ./machin-game-flappy  (run it from this directory so it finds assets/)"
