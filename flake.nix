{
  description = "Angel nix-darwin system flake";

  inputs = {
    # Nixpkgs channel to pull packages from.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Home-manager integration.
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Homebrew

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, ... }:
  let
    system = "aarch64-darwin"; # or "x86_64-darwin"
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # Build darwin flake using:
    # $ sudo darwin-rebuild switch --flake .#angel     
    darwinConfigurations."angel" = nix-darwin.lib.darwinSystem {
      system = system;
      modules = [

        ./modules/configuration.nix
        ./modules/homebrew.nix
        ./modules/apps.nix
        # Integrate home-manager into nix-darwin
        home-manager.darwinModules.home-manager
        {
          users.users.angel.home = "/Users/angel";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.angel = import ./modules/home.nix;
        }
      ];
      specialArgs = { inherit inputs; };
    };

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nodejs_25
      ];
    };
  };
}
