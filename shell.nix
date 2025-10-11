{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Nim compiler
    nim

    # Raylib for graphics
    raylib

    # Build tools
    gcc
    pkg-config

    # Optional: Nim language server for IDE support
    nimlsp
  ];

  shellHook = ''
    echo "Habits App Development Environment"
    echo "=================================="
    echo "Nim version: $(nim --version | head -1)"
    echo ""
    echo "To run the app:"
    echo "  nim c -r main.nim"
    echo "  or: ./run.sh"
    echo ""
  '';

  # Environment variables for raylib
  NIX_CFLAGS_COMPILE = "-I${pkgs.raylib}/include";
  NIX_LDFLAGS = "-L${pkgs.raylib}/lib -lraylib";
}
