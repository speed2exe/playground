{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    glfw
    glew
    mesa
    freetype
    pkg-config
  ];

  # for C project, lsp support
  # C_INCLUDE_PATH = pkgs.lib.concatStringsSep ":" [
  #   "${pkgs.glibc.dev}/include"
  #   "${pkgs.glfw}/include"
  #   "${pkgs.glew.dev}/include"
  #   "${pkgs.libGLU.dev}/include"
  #   "${pkgs.libGL.dev}/include"
  #   "${pkgs.mesa.dev}/include"
  #   "${pkgs.freetype.dev}/include"
  # ];

  shellHook = ''
    echo "Environment set up for OpenGL development."
  '';
}
