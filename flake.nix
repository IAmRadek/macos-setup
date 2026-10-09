{
  description = "Minimal macOS Nix setup";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # tmux plugins; `nix flake update` fetches the latest commit
    kube-tmux = {
      url = "github:jonmosco/kube-tmux";
      flake = false;
    };
    tmux-k8s-context-switcher = {
      url = "github:IAmRadek/tmux-k8s-context-switcher";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      darwin,
      home-manager,
      ...
    }@inputs:
    let
      mkHost =
        host:
        darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useUserPackages = true;
                useGlobalPkgs = true;
                extraSpecialArgs = { inherit inputs; };
                sharedModules = [ ./modules/home.nix ];
              };
            }
            host
          ];
        };
    in
    {
      darwinConfigurations = {
        "rdwk" = mkHost ./hosts/rdwk.nix;
        "r__d" = mkHost ./hosts/r__d.nix;
      };
    };
}
