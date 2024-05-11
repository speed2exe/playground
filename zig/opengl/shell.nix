{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    gcc
    glfw
    glew
    mesa
    freetype
  ];

  C_INCLUDE_PATH = pkgs.lib.concatStringsSep ":" [
    "${pkgs.glibc.dev}/include"
    "${pkgs.glfw}/include"
    "${pkgs.glew.dev}/include"
    "${pkgs.mesa.dev}/include"
    "${pkgs.freetype.dev}/include"
  ];

  shellHook = ''
    echo "Environment set up for OpenGL development."
  '';
}
