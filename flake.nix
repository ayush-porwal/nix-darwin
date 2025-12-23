{
  description = "Personal nix-darwin system flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Installing directly via opencode's flake.nix because the latest version is not available in nixpkgs
    # This can be replaced with npm i opencode for simplicity, but this i did for now as an example for
    # future myself to know how to add binaries directly from github if a flake.nix is avaliable in the source code
    opencode = {
      url = "github:sst/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      opencode,
      nix-darwin,
      nix-homebrew,
      home-manager,
    }:
    let
      system = "aarch64-darwin";
      username = "ayush.porwal";
      homedir = "/Users/${username}";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      operator-mono = pkgs.callPackage ./operator-mono.nix { };

      # Home Manager configuration
      hmConfig =
        { pkgs, ... }:
        {
          home.stateVersion = "25.11";

          # This "mounts" the file from the current flake folder to the home folder
          home.file.".zshrc_local".source = ./.zshrc_local;

          home.packages = [
            pkgs.uv
            pkgs.gh
            pkgs.go
            pkgs.bws
            pkgs.git
            pkgs.zig
            pkgs.nixd
            pkgs.rustc
            pkgs.helix
            pkgs.cargo
            pkgs.direnv
            pkgs.neovim
            pkgs.awscli2
            pkgs.postgresql
            pkgs.lazydocker
            pkgs.nixfmt-rfc-style
            opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
          programs.git.enable = true;
          programs.starship.enable = true;

          # Enable alternative shell support in nix-darwin.
          programs.zsh = {
            enable = true;
            syntaxHighlighting.enable = true;
            autosuggestion.enable = true;
            initContent = ''
              if [ -f ~/.zshrc_local ]; then
                source ~/.zshrc_local
              fi
            '';
          };
        };
      # System-wide configuration
      configuration =
        { pkgs, ... }:
        {
          system.primaryUser = username;

          # System packages (CLI tools that need root / all users)
          environment.systemPackages = [
            pkgs.vscode
            pkgs.colima
            pkgs.docker
            pkgs.wezterm
            pkgs.docker-compose
          ];
          fonts = {
            packages = [
              operator-mono # comes from the operator-mono.nix file
              pkgs.cascadia-code
              pkgs.nerd-fonts.fira-code
              pkgs.nerd-fonts.geist-mono
              pkgs.nerd-fonts.ubuntu-mono
              pkgs.nerd-fonts.victor-mono
              pkgs.nerd-fonts.jetbrains-mono
            ];
          };

          # Homebrew GUI apps
          homebrew = {
            enable = true;
            casks = [
              "zen"
              "zed"
              "zoom"
              "shottr"
              "claude"
              "firefox"
              "discord"
              "ghostty"
              "anytype"
              "pgadmin4"
              "obsidian"
              "capacities"
              "google-drive"
              "sublime-text"
              "google-chrome"
              "microsoft-edge"
              "jetbrains-toolbox"
              "karabiner-elements"
            ];
            masApps = {
              "WhatsApp Messenger" = 310633997;
              #"Microsoft Copilot" = 6738511300;
              # add readera
            };
            onActivation.cleanup = "zap";
          };

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          # Allow installation of unfree packages.
          nixpkgs.config.allowUnfree = true;

          # Define macOS user for nix-darwin & home-manager
          users.users.${username} = {
            home = homedir;
          };
        };
    in
    {
      darwinConfigurations."Ayushs-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          configuration

          { _module.args = { inherit inputs; }; }

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = username;
            };
          }
          # Home Manager integration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = {
              imports = [ hmConfig ];
            };
          }
        ];
      };
    };
}
