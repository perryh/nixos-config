{
  inputs = {
    # Release branch for stability. Upgrade deliberately via:
    #   nix flake lock --update-input nixpkgs
    # then commit flake.lock + rebuild all hosts.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Rolling nixpkgs. Used ONLY for groups listed in perry.unstableGroups
    # (see common/common.nix) — never for the OS itself.
    #
    # Tracks the rolling branch. Was temporarily pinned to a 2026-09-10 rev
    # (b1822af: opencode 1.18.29 + bun 1.3.13) because rolling had bumped bun
    # to 1.4.2 and opencode's nixpkgs derivation compiles the CLI from source
    # with nixpkgs' `bun`, which crashed on bun 1.4.2
    # (github.com/anomalyco/opencode/issues/48372). Upstream fixed it in
    # opencode 1.18.31, so this follows rolling again.
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
          # allowed (browsers/chat have unfree apps). pkgs/ holds repo-local
          # overlays for packages not in nixpkgs; they must be applied to BOTH
          # sets so groups can reference them from either source.
          unstablePkgs = import nixpkgs-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
            overlays = [ (import ./pkgs/dsh) ];
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
    nixosConfigurations."perry-office" = mkHost "perry-office";
    # nixosConfigurations.desktop = mkHost "desktop";
  };
}
