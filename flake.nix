{
  description = "Angel's personal configuration for macOS";

  inputs = {
    # Core / system
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Zellij 0.45 adds Kitty graphics passthrough and stops advertising Sixel
    # when the host terminal (Ghostty) does not support it.
    nixpkgs-zellij.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    herdr.url = "github:herdrdev/herdr";

    # Desktop / theming
    zjstatus.url = "github:dj95/zjstatus";

    catppuccin.url = "github:catppuccin/nix";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin-zen.url = "github:catppuccin/zen-browser";
    catppuccin-zen.flake = false;

    # Agent skills (non-flake sources)
    ponytail.url = "github:DietrichGebert/ponytail";
    ponytail.flake = false;

    archify.url = "github:tt-a1i/archify";
    archify.flake = false;

    context7.url = "github:upstash/context7";
    context7.flake = false;

    cursor-plugins.url = "github:cursor/plugins";
    cursor-plugins.flake = false;

    superpowers.url = "github:obra/superpowers";
    superpowers.flake = false;

    documentation.url = "github:mcollina/skills";
    documentation.flake = false;

    agent-skills.url = "github:magnus919/agent-skills";
    agent-skills.flake = false;
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nix-homebrew, zjstatus, catppuccin, ... }:
  let
    # Change for your own username and hostname
    username = "angel";
    hostname = "angel-flake";
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#your-hostname
    # sudo darwin-rebuild switch --flake .#your-hostname
    darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs username hostname; };
      modules = [
        ./darwin
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;

            extraSpecialArgs = { inherit inputs username hostname; };
            
            users.${username} = import ./home;
          };
        }
      ];
    };
  };
}
