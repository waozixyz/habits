# shell.nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    pkg-config
    raylib
    gcc
    gdb
    ccache
    valgrind
    libsodium
  ];

  shellHook = ''
    echo "Habits development environment ready!"
    echo "Available commands:"
    echo "  make        - Build the project"
    echo "  make clean  - Clean build artifacts"
  '';
}
