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

    # OMP coding agent (omp.sh). Used ONLY for its home-manager module
    # (programs.omp, owns ~/.omp/agent/config.yml declaratively); the omp
    # package itself comes from the nixpkgs-unstable pin in home.nix, so this
    # input adds no build of its own. Refresh: nix flake update omp.
    omp.url = "github:can1357/oh-my-pi";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, omp }: let
    mkHost = name:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit omp;
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
    # Mac (standalone home-manager, no NixOS host): reuses common/home.nix
    # verbatim — same home packages, omp settings + models, zsh, git identity.
    # The same nixpkgs-unstable pin is imported for darwin, so programs.omp
    # and the home herdr resolve to the identical version as the Linux hosts.
    # Apple Silicon — for an Intel Mac, switch both systems to x86_64-darwin.
    # No repo-local overlays: home.nix only needs unstablePkgs.omp + .herdr.
    homeConfigurations.perry-mac =
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
        extraSpecialArgs = { unstablePkgs = import nixpkgs-unstable { system = "aarch64-darwin"; }; };
        modules = [
          ({ pkgs, ... }: {
            home.homeDirectory = "/Users/perryh";
            home.username = "perryh";
            nix.package = pkgs.nix;
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
          })
          omp.homeManagerModules.default
          ./common/home.nix
        ];
      };
    # nixosConfigurations.desktop = mkHost "desktop";
  };
}
