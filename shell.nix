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

    # Lua (for Kryon Lua bindings parity)
    lua
    lua54Packages.lua

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
    echo "Try: kryon run main.nim"
    echo ""
  '';

  # Make sure pkg-config sees SDL3 libs (same as Kryon env)
  PKG_CONFIG_PATH = pkgs.lib.makeSearchPath "lib/pkgconfig" [ sdl3 sdl3_ttf sdl3_image ];
}
