{ pkgs ? import <nixpkgs> { } }:

# let
#    unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {};
# in

pkgs.mkShell {

  buildInputs = with pkgs; [
    clang
  ];

  C_INCLUDE_PATH = "${pkgs.glibc.dev}/include";

  # packages = with pkgs; [
  #   pkg-config
  #   openssl
  #   grpc-tools
  #   rustup
  # ];

  NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
  NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
    # ... add your runtime dependencies here
  ];

  shellHook = ''
    # export PROTOC=$(which protoc)
  '';
}
