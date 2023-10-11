{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager }:
    let
      mkHost = hostName: system:
        nixpkgs.lib.nixosSystem {
          system = system;
          pkgs = nixpkgs.legacyPackages.${system};

          specialArgs = {
            nixpkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          };

          modules = [
            ./modules

            (import ./configuration.nix)

            (import ./hosts/${hostName})

            ({
              system.configurationRevision = if (self ? rev) then
                self.rev
              else
                throw "refuse to build: git tree is dirty";
              system.stateVersion = "23.05";
              imports = [
                "${nixpkgs}/nixos/modules/installer/scan/not-detected.nix"
                "${nixpkgs}/nixos/modules/profiles/hardened.nix"
              ];
            })

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];
        };
    in {
      nixosConfigurations = {
        exampleHost = mkHost "exampleHost" "x86_64-linux";
      };
    };
}
