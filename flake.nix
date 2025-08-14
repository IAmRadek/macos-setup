{
  description = "Minimal macOS Nix setup";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/25.05";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin }: {
    darwinConfigurations = {
      "PersonalMacbookPro" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./configuration.nix
          ./hosts/mbp.nix
        ];
      };
    };
  };
}
