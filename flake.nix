{
	inputs.nixpkgs.url = github:nixos/nixpkgs;
	outputs = inputs: rec {
		packages = inputs.nixpkgs.lib.mapAttrs (system: pkgs: {
			default = pkgs.writers.writeBashBin "figman" ''
				export PATH=${pkgs.lib.escapeShellArg (pkgs.lib.makeBinPath [
					pkgs.bash
					pkgs.coreutils-full
				])}
				echo "$0" "$@"
				. ${./src}/manager.sh
			'';
		}) inputs.nixpkgs.legacyPackages;
	};
}
