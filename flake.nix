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
          name = "figman";
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
              LUA_PATH="${src}/?.lua;$LUA_PATH" lua ${src}/main.lua "$@"
            ''}" $out/bin/figman

            wrapProgram $out/bin/figman \
              --prefix PATH : ${pkgs.lib.makeBinPath buildInputs}\
          '';
        };
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
