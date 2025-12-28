{ pkgs ? import <nixpkgs> {} }:

let
  sdl3 = pkgs.sdl3;
  sdl3_ttf = pkgs.sdl3-ttf;
  sdl3_image = pkgs.sdl3-image;
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Core toolchain
    nim
    nimble
    gcc
    gnumake
    pkg-config

    # SDL3 stack (matches Kryon dev env)
    sdl3
    sdl3_ttf
    sdl3_image

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

    # Dev tools
    git
    gdb
    which
    tree
  ];

  shellHook = ''
    echo "Habits App Dev Environment (Kryon-aligned)"
    echo "==========================================="
    echo "Nim: $(nim --version | head -1)"
    echo "SDL3: ${sdl3}"
    echo "SDL3_ttf: ${sdl3_ttf}"
    echo "SDL3_image: ${sdl3_image}"
    echo ""
    echo "Try: kryon run main.nim or kryon run main.lua"
    echo ""

    # Add storage plugin to library paths
    export LD_LIBRARY_PATH="/mnt/storage/Projects/kryon-storage/build:''${LD_LIBRARY_PATH:-}"
    export LUA_PATH="/mnt/storage/Projects/kryon-storage/bindings/lua/?.lua;;"
    export LUA_CPATH="/mnt/storage/Projects/kryon-storage/build/?.so;;"
  '';

  # Make sure pkg-config sees SDL3 libs (same as Kryon env)
  PKG_CONFIG_PATH = pkgs.lib.makeSearchPath "lib/pkgconfig" [ sdl3 sdl3_ttf sdl3_image ];
}
