{
  inputs = {
    # Release branch for stability. Upgrade deliberately via:
    #   nix flake lock --update-input nixpkgs
    # then commit flake.lock + rebuild all hosts.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Rolling nixpkgs. Used ONLY for groups listed in perry.unstableGroups
    # (see common/common.nix) — never for the OS itself. Refresh with:
    #   nix flake update nixpkgs-unstable
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager }: let
    mkHost = name:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          # Package set for perry.unstableGroups: rolling branch, unfree
          # allowed (browsers/chat have unfree apps).
          unstablePkgs = import nixpkgs-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
        modules = [
          ./common/common.nix
          home-manager.nixosModules.home-manager
          ./hosts/${name}.nix
          ./hosts/${name}-hardware.nix
        ];
      };
  in {
    nixosConfigurations."perry-eb" = mkHost "perry-eb";
    # add more hosts here as you bring machines online:
    # nixosConfigurations.desktop = mkHost "desktop";
  };
}
