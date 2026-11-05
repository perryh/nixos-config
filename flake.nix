{
  inputs = {
    # Release branch for stability. Upgrade deliberately via:
    #   nix flake lock --update-input nixpkgs
    # then commit flake.lock + rebuild all hosts.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Rolling nixpkgs. Used ONLY for groups listed in perry.unstableGroups
    # (see common/common.nix) — never for the OS itself — plus the per-user
    # home.nix packages that are unstable-only or want a newer build than the
    # stable pin (omp, herdr, opencode).
    #
    # Tracks the rolling branch (no pin needed: opencode comes from here and is
    # itself built from source in nixpkgs, so its bun is whatever unstable
    # pairs it with).
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
          # allowed (browsers/chat have unfree apps). No repo-local overlays
          # anymore (pkgs/ was removed with dsh).
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
    nixosConfigurations."perry-office" = mkHost "perry-office";
    # Mac (standalone home-manager, no NixOS host): reuses common/home.nix
    # verbatim — same home packages, omp settings + models, zsh, git identity.
    # The same nixpkgs-unstable pin is imported for darwin, so programs.omp,
    # programs.opencode and the home herdr resolve to the identical version as
    # the Linux hosts. Apple Silicon — for an Intel Mac, switch both systems to
    # x86_64-darwin. Groups are expanded from common/pkg-groups.nix, so no
    # repo-local packages are needed here.
    homeConfigurations.perry-mac =
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
        };
        extraSpecialArgs = {
          unstablePkgs = import nixpkgs-unstable { system = "aarch64-darwin"; };
          # home-manager CLI, from the SAME release-26.05 flake input as the
          # module above (so the command and the module stay version-aligned).
          # home-manager is not in nixpkgs — the CLI only ships via the
          # flake's packages.<system>.home-manager.
          homeManagerPkgs = home-manager.packages.aarch64-darwin;
        };
        modules = [
          ({ pkgs, unstablePkgs, homeManagerPkgs, ... }:
            let
              lib = pkgs.lib;
              # A Mac has no NixOS system, so perry.systemGroups /
              # environment.systemPackages (common/common.nix) do not exist
              # here. It selects groups from the SAME definitions
              # (common/pkg-groups.nix) the hosts use, the same way a NixOS
              # host does in hosts/<name>.nix. The non-GUI groups only —
              # desktop GUI groups (firefox/ghostty/rustdesk/vscode-fhs/
              # LibreOffice) stay Linux-only.
              stableGroups = import ./common/pkg-groups.nix { inherit pkgs; };
              unstableGroups = import ./common/pkg-groups.nix { pkgs = unstablePkgs; };
              # Each group keeps the source the NixOS hosts take it from, so
              # versions stay identical machine to machine. `dev` and `langs`
              # are the only non-GUI groups both hosts track from
              # nixpkgs-unstable.
              cliGroups = [ "core" "net" "tools" "backup" ];
              cliUnstableGroups = [ "langs" "dev" ];
              # Drop what nixpkgs marks Linux-only (iputils, ethtool, parted,
              # udisks) instead of hand-maintaining a darwin subset. Excluded
              # on purpose: `containers` (docker daemon does not apply on
              # darwin) and `ai` (herdr is the only member and reaches the Mac
              # through common/home.nix instead).
              forPlatform = builtins.filter
                (p: lib.meta.availableOn pkgs.stdenv.hostPlatform p);
              cliPackages = forPlatform
                (builtins.concatLists (map (g: stableGroups.${g}) cliGroups)
                  ++ builtins.concatLists (map (g: unstableGroups.${g}) cliUnstableGroups));
            in {
              home.homeDirectory = "/Users/perryh";
              home.username = "perryh";
              # Install the home-manager CLI into the profile so the plain
              # `home-manager switch --flake ~/git/nixos-config#perry-mac`
              # command works, plus the CLI groups above (merges with
              # common/home.nix's home.packages: ripgrep/fzf/eza/herdr/omp).
              home.packages = [ homeManagerPkgs.home-manager ] ++ cliPackages;
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
