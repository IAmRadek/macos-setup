{
  description = "Minimal macOS Nix setup";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin }: {
    darwinConfigurations = {
      "rd" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./configuration.nix
          ./hosts/mbp.nix
        ];
      };
    };
  };
}
