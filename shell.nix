{ pkgs ? import <nixpkgs> {} }:

let
  sdl3 = pkgs.sdl3;
  sdl3_ttf = pkgs.sdl3-ttf;
  sdl3_image = pkgs.sdl3-image;
  raylib = pkgs.raylib;
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Core toolchain
    gcc
    gnumake
    pkg-config

    # SDL3 stack (matches Kryon dev env)
    sdl3
    sdl3_ttf
    sdl3_image

    # Raylib (for desktop backend)
    raylib

    # Terminal/TUI backend support
    libtickit

    # LuaJIT (for Kryon Lua bindings parity)
    luajit

    # Graphics system libs
    libGL
    libglvnd
    xorg.libX11
    xorg.libXrandr
    xorg.libXi
    xorg.libXcursor
    libxkbcommon

    # Text shaping and BiDi support (required for kryon CLI)
    harfbuzz
    freetype
    fribidi

    # Dev tools
    git
    gdb
    which
    tree
  ];

  shellHook = ''
    echo "Habits App Dev Environment (Kryon-aligned)"
    echo "==========================================="
    echo "SDL3: ${sdl3}"
    echo "SDL3_ttf: ${sdl3_ttf}"
    echo "Raylib: ${raylib}"
    echo ""

    # Kryon paths
    export KRYON_ROOT="/mnt/storage/Projects/KryonLabs/kryon"
    export KRYON_PLUGINS="/mnt/storage/Projects/KryonLabs/kryon-plugins"

    # Add kryon and plugin libraries to path
    export LD_LIBRARY_PATH="$KRYON_ROOT/build:$KRYON_PLUGINS/datetime/build:$KRYON_PLUGINS/storage/build:$LD_LIBRARY_PATH"
    export LUA_PATH="$KRYON_ROOT/bindings/lua/?.lua;$KRYON_ROOT/bindings/lua/?/init.lua;$KRYON_PLUGINS/datetime/bindings/lua/?.lua;$KRYON_PLUGINS/storage/bindings/lua/?.lua;./?.lua;./?/init.lua;;"
    export LUA_CPATH="$KRYON_PLUGINS/datetime/build/libkryon_?.so;$KRYON_PLUGINS/storage/build/libkryon_?.so;;"

    # Add kryon CLI to PATH if built
    if [ -f "$KRYON_ROOT/cli/kryon" ]; then
      export PATH="$KRYON_ROOT/cli:$PATH"
      echo "Kryon CLI: $KRYON_ROOT/cli/kryon"
    fi

    echo ""
    echo "Try: kryon build --target web"
  '';

  # Make sure pkg-config sees SDL3, raylib, and text shaping libs
  PKG_CONFIG_PATH = pkgs.lib.makeSearchPath "lib/pkgconfig" [
    sdl3 sdl3_ttf sdl3_image raylib
    pkgs.harfbuzz pkgs.freetype pkgs.fribidi
  ];
}
