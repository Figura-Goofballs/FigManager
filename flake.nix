# vim: ts=2 sts=2 sw=2 et fdm=indent ft=nix

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {nixpkgs, flake-utils, ...}: flake-utils.lib.eachDefaultSystem (
    system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in rec {
      packages = {
        default = pkgs.stdenv.mkDerivation rec {
          pname = "figman";
          version = "1";
          src = ./src;

          buildInputs = with pkgs; [
            bash

            (lua54Packages.lua.withPackages (ps: with ps; [
              dkjson
              luasocket
              luasec
              luafilesystem
            ]))
          ];
          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            mkdir -p $out/bin
            cp "${pkgs.writeShellScript "figman.sh" ''
              lua=$(dirname $(dirname $(realpath $(command -v lua))))
              LUA_PATH="${src}/?.lua;$lua/share/lua/5.4/?.lua" LUA_CPATH="$lua/lib/lua/5.4/?.so" lua ${src}/main.lua "$@"
            ''}" $out/bin/figman

            wrapProgram $out/bin/figman \
              --prefix PATH : ${pkgs.lib.makeBinPath buildInputs}\
          '';
        };
      };

      checks = {
        prettier = pkgs.runCommand "prettier-check" {
          buildInputs = [pkgs.nodePackages.prettier];
        } ''
          prettier --check ${./.}
          touch $out
        '';
      };

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs.lua54Packages; [
          lua
          dkjson # JSON
          luasocket # HTTP
          luasec
          luafilesystem # FS
        ];
      };
    }
  );
}
