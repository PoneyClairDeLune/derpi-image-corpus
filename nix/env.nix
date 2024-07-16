let
	pkgs = import <nixpkgs> {
		config = {};
		overlays = [];
	};
in
pkgs.mkShell {
	packages = with pkgs; [
		# Included in BusyBox
		ncurses
		less
		# Supported shells
		bash
		zsh
		# System utilities
		procps
		tree
		# Required utilities
		git
		nano
		curl
		gzip
		gnupg
		# Development dependencies
		libjxl
		libwebp
		mozjpeg
		libavif
		vips
	];
	GIT_EDITOR = "${pkgs.nano}/bin/nano";
	shellHook = ''
		export ZDOTDIR=$PWD/nix/zsh
		export XDG_CONFIG_HOME=$PWD/nix
		export PATH=$PWD:$PATH
		export SOURCE_DIR=$(./shx sourceDir)
	'';
}