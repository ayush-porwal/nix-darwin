{
  description = "Personal nix-darwin system flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
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
          home.packages = [
            pkgs.uv
            pkgs.gh
            pkgs.go
            pkgs.git
            pkgs.zig
            pkgs.nixd
            pkgs.rustc
            pkgs.cargo
            pkgs.neovim
            pkgs.awscli2
            pkgs.nixfmt-rfc-style
          ];
          programs.zsh.enable = true;
          programs.zsh.autosuggestion.enable = true;
          programs.zsh.syntaxHighlighting.enable = true;
          programs.git.enable = true;
          programs.starship.enable = true;
          programs.zsh.initContent = ''
            # Cargo related
            export PATH="$HOME/.cargo/bin:$PATH"

            # Docker / Colima Socket
            export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
            # Alias for starting Colima with specific configurations
            alias dstop="colima stop"
            alias dlogs="colima logs"
            alias dstatus="colima status"
            alias drestart="colima restart"
            alias dstart="colima start --cpu 2 --memory 4 --vm-type=vz --vz-rosetta"

            #NVM related
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
          '';
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
            # pkgs.gcc
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
              "firefox"
              "discord"
              "ghostty"
              "anytype"
              "obsidian"
              "capacities"
              "google-drive"
              "google-chrome"
              "microsoft-edge"
              "jetbrains-toolbox"
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

          # Enable alternative shell support in nix-darwin.
          programs.zsh.enable = true;

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
