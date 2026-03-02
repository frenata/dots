{
  description = "Example nix-darwin system flake";


  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      nixpkgs.config.allowUnfree = true;
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
      [ pkgs.neovim
	pkgs.httpie
	pkgs.tmux
	pkgs.alacritty
	#pkgs.ghostty
  pkgs.rustup
	pkgs.emacs
	pkgs.jq
	pkgs.git
	pkgs.jujutsu
	pkgs.jjui
	pkgs.git-lfs
	pkgs.unixtools.watch
	pkgs.ranger
	pkgs.atuin
  pkgs.fd
  pkgs.fzf
	pkgs.tree
	pkgs.gnutar
	pkgs.graphviz
	pkgs.tldr
	pkgs.htop
	pkgs.inetutils
	pkgs.nmap
	# pkgs.gimp
	pkgs.packer
	pkgs.docker
	pkgs.clojure
	pkgs.stack
	pkgs.go

  pkgs.hack-font
	pkgs.devcontainer
	pkgs.just
  pkgs.redis
  pkgs.starship

  # overstory stuff
  # pkgs.poetry
  pkgs.uv
  pkgs.pyenv
  pkgs.google-cloud-sdk
  #pkgs.python312Packages.keyrings-google-artifactregistry-auth
  #pkgs.python311Packages.keyrings-google-artifactregistry-auth
  pkgs.tailscale
  pkgs.pgcli
        ];

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;
      system.primaryUser = "frenata";
      nix.enable = false; # allow determinate to take over

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # via https://nixcademy.com/posts/nix-on-macos/
      # security.pam.enableSudoTouchIdAuth = true;
      system.defaults = {
        dock.autohide = true;
        dock.mru-spaces = false;
        finder.AppleShowAllExtensions = true;
        finder.FXPreferredViewStyle = "clmv";
        # loginwindow.LoginwindowText = "nixcademy.com";
        screencapture.location = "~/Pictures/screenshots";
        screensaver.askForPasswordDelay = 10;
      };

      nix.extraOptions = ''
        extra-platforms = x86_64-darwin aarch64-darwin
      '';
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."roar" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
