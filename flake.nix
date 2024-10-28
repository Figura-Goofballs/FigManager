{
	inputs.fia.url = github:poollovernathan/fia;
	outputs = inputs: rec {
		packages = inputs.fia.lib.perSystem (pkgs: {
			default = pkgs.writers.writeBashBin "fig-manager" ''
				export PATH=${pkgs.lib.escapeShellArg (pkgs.lib.makeBinPath [
					pkgs.bash
					pkgs.coreutils-full
				])}
				echo "$0" "$@"
				. ${./src}/manager.sh
			'';
		});
	};
}
