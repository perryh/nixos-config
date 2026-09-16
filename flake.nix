{
  inputs = {
    # Release branch for stability. Upgrade deliberately via:
    #   nix flake lock --update-input nixpkgs
    # then commit flake.lock + rebuild all hosts.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Rolling nixpkgs. Used ONLY for groups listed in perry.unstableGroups
    # (see common/common.nix) — never for the OS itself.
    #
    # Pinned to a 2026-09-10 rev (opencode 1.18.29, bun 1.3.13, herdr 0.9.0).
    # ROLLING nixpkgs-unstable at the time of pinning had bumped bun to 1.4.2
    # (2026-09-12) and opencode to 1.18.30 (2026-09-10). opencode's nixpkgs
    # derivation compiles the CLI from source with nixpkgs' `bun`, and that
    # compiled-bun build path crashes in SystemPrompt.environment
    # (github.com/anomalyco/opencode/issues/48372) on bun 1.4.2 — the official
    # prebuilt release binary is fine, only the source-compiled path breaks.
    # Downgrading to this rev drops both opencode to 1.18.29 AND bun to 1.3.13,
    # which is the build combination the prebuilt binary shipped with.
    # Re-pin to rolling (url = "github:NixOS/nixpkgs/nixpkgs-unstable") once
    # upstream fix #48397 lands in nixpkgs.
    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/b1822af09f8d709b9259f63d420d184037ce1d3a";
      # No `ref`: `nix flake update nixpkgs-unstable` re-resolves the default
      # branch (rolling) in one step when you want to unpin.
    };

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
    # nixosConfigurations.desktop = mkHost "desktop";
  };
}
