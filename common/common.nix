# Shared across ALL hosts — anything that should be identical on every machine.
# Desktop/GUI-related options live here too, so every machine gets the same
# stack; override in hosts/<name>.nix if a machine differs (e.g. headless).
#
# Package groups: pick per-host which named groups (common/pkg-groups.nix) to
# install via perry.systemGroups. Default = all groups (desktop). A headless
# server would set:  perry.systemGroups = [ "core" "dev" "containers" ];
{ config, pkgs, lib, unstablePkgs, omp, ... }:

let
  groups = import ./pkg-groups.nix { inherit pkgs; };
  # Same group definitions, built from the rolling nixpkgs-unstable set.
  unstableGroupsSet = import ./pkg-groups.nix { pkgs = unstablePkgs; };
  validGroups = lib.concatStringsSep ", " (lib.attrNames groups);
  # `config` here is the final merged config, so host overrides to
  # perry.systemGroups (and its default) are visible. Groups listed in
  # perry.unstableGroups are dropped from the stable set and taken from
  # unstable instead (never installed from both).
  enabledGroups = map (g:
    groups.${g} or (throw (
      "perry.systemGroups: unknown group '${g}' (valid: " + validGroups + ")"
    ))
  ) (lib.subtractLists config.perry.unstableGroups config.perry.systemGroups);
  unstableGroupPkgs = map (g:
    unstableGroupsSet.${g} or (throw (
      "perry.unstableGroups: unknown group '${g}' (valid: " + validGroups + ")"
    ))
  ) config.perry.unstableGroups;
  # Group side effects fire if the group is enabled from either source.
  anyEnabledGroups = lib.unique
    (config.perry.systemGroups ++ config.perry.unstableGroups);
in
{
  options.perry.systemGroups = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = lib.attrNames groups;
    example = [ "core" "dev" "containers" ];
    description = "Which named package groups (common/pkg-groups.nix) to install. Headless hosts drop the GUI groups but keep core.";
  };

  options.perry.unstableGroups = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "browsers" "terminals" ];
    description = ''
      Package groups (same names as pkg-groups.nix) to install from the
      rolling nixpkgs-unstable branch instead of the stable pin. Members of
      these groups are removed from perry.systemGroups' stable set, so each
      group is installed exactly once. Requires the group also be in
      perry.systemGroups (or the default all-groups) for side effects.
    '';
  };

  config = {
    system.stateVersion = "26.05";
    time.timeZone = "America/Los_Angeles";

    # Repo-local overlays for packages not (yet) in nixpkgs (see pkgs/).
    # Applied to the stable pkgs here; the unstable set (flake.nix) applies
    # the same overlays so groups can reference them from either source — except
    # opencode, which is stable-only on purpose (it is built with this set's bun,
    # see pkgs/opencode/default.nix).
    nixpkgs.overlays = [
      (import ../pkgs/dsh)
      (import ../pkgs/opencode)
    ];

    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Enable nix-command + flakes declaratively (managed /etc/nix/nix.conf)
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Latest kernel (mkDefault: hosts can override, e.g. perry-office pins the
    # distro default because the nvidia module lags bleeding-edge kernels)
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    # --- shared user account ---
    # perryh already exists on each host with a real password; with
    # users.mutableUsers (default) existing passwords are left untouched, so no
    # password option is needed here. For a brand-new user on a host, set
    # hashedPassword (or initialHashedPassword) instead.
    users.users.perryh = {
      isNormalUser = true;
      description = "Perry Huang";
      # Login shell: zsh (oh-my-zsh is configured per-user in common/home.nix).
      # NixOS defaults everyone to bash (users.defaultUserShell), so without
      # this terminals would run bash and never source ~/.zshrc.
      shell = pkgs.zsh;
      extraGroups = [ "networkmanager" "wheel" ]
        ++ lib.optionals (lib.elem "containers" anyEnabledGroups) [ "docker" ];
      packages = with pkgs; [
        kdePackages.kate
      ];
      # Mirror of https://github.com/perryh.keys (keep in sync when keys are
      # added/removed there). The perry.huang@gmail.com-commented key is the
      # Hermes agent access key (perry-mini / vm2).
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYQ1+Nb+RcLPLz9VAW9uyITqSfZQPUuIQXgTw0eUFRL"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEEJJ6/p05Yq8l07mlwFgQd1DVOV9rZ6l2d6qyAqNMUa"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEvYwsZafD4nMiMjBGZ+mjVD40PdzfqFUsZHnKv8LYvK"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO6SOPUNcvb91Tq6t06pEMWp8KeV3btxtpoY0dEMduPC perry.huang@gmail.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINH+LQZ4+C4d2F24/gn8jbIaHezeG/rzGR4Ve5+pOdIO"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ5oIQNpW9x3/zi1HqVmlW4tkrXIaF9o/mWh2wKlj3dL"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAvrs3K8Wlo0X25si1uCMPpnueLGM82Jt0iLnmLv9HcY"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1/xvRqPOYz2T4vRqMz/ZXVQ/DgvCE9sGxrXp2VxoWV"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE2QE1ZjxH4nkkSeJ9XwTInj1GwO9Z7/wplklORJQ15W"
      ];
    };

    # --- shared system packages (identical versions on every host) ---
    # Everything is a named group (pkg-groups.nix); selected by
    # perry.systemGroups (+ perry.unstableGroups for rolling versions).
    environment.systemPackages =
      builtins.concatLists enabledGroups
      ++ builtins.concatLists unstableGroupPkgs;

    # --- networking ---
    networking.networkmanager.enable = true;
    services.tailscale.enable = true;

    # --- docker (when the "containers" group is on, from either source) ---
    virtualisation.docker.enable = lib.elem "containers" anyEnabledGroups;

    # --- restic backups (when the "backup" group is on, from either source) ---
    # The module generates a systemd unit (restic-backups-<name>) + timer per
    # entry in services.restic.backups. Per-host repo settings live in the
    # gitignored hosts/<name>.restic-backup.local.nix, so no backup secrets
    # ever land in this public repo; without that file the group installs the
    # client only.
    #
    # To set up a backup on a host (e.g. perry-office):
    #   1. Password (secret, NOT in the repo):
    #        openssl rand -base64 48 | sudo tee /etc/nixos/restic-password
    #        sudo chmod 600 /etc/nixos/restic-password
    #   2. Write hosts/<name>.restic-backup.local.nix exporting an
    #      attrset of backup entries, e.g.:
    #        {
    #          home = {
    #            paths = [ "/home/perryh" "/etc/nixos" ];
    #            repository = "sftp:perryh@100.90.212.18:/backups/perry-office";
    #            passwordFile = "/etc/nixos/restic-password";
    #            pruneOpts = [ "--keep-daily 7" "--keep-weekly 5"
    #                          "--keep-monthly 12" "--keep-yearly 1" ];
    #            # timerConfig = { OnCalendar = "daily"; Persistent = true; };
    #          };
    #        }
    #      Module requirements (assertions): exactly one of `repository`,
    #      `repositoryFile` or `environmentFile`, AND `passwordFile` (or
    #      `environmentFile`). Default timer: daily, Persistent.
    #   3. Rebuild; then: sudo systemctl start restic-backups-home.service
    #      (or wait for the timer). `restic ls`/`restic check` use the same
    #      env via the createWrapper script the module adds to system PATH.
    services.restic.backups =
      let
        localFile = ./hosts/${config.networking.hostName}.restic-backup.local.nix;
      in
      if lib.elem "backup" anyEnabledGroups && builtins.pathExists localFile
      then import localFile
      else { };

    # --- shared services ---
    services.openssh.enable = true;
    services.printing.enable = true;

    # zsh is perryh's login shell (users.users.perryh.shell); the NixOS
    # programs.zsh module provides /etc/zshenv|zprofile|zshrc and registers
    # zsh in environment.shells. The users module asserts programs.zsh.enable
    # whenever a user's shell is pkgs.zsh.
    programs.zsh.enable = true;

    # Sound with pipewire
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # Use the WirePlumber session manager
      # wireplumber.enable = true;
    };

    # --- desktop: KDE Plasma 6 (override per-host for headless machines) ---
    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # --- browsers ---
    # Tied to the "browsers" group (either source) so headless hosts, which
    # drop GUI groups, don't still get a browser.
    programs.firefox.enable = lib.elem "browsers" anyEnabledGroups;
    # The firefox module (default-browser registration, wrapper) must use the
    # same build as the group: unstable when the group is unstable-tracked.
    programs.firefox.package =
      if lib.elem "browsers" config.perry.unstableGroups
      then unstablePkgs.firefox else pkgs.firefox;

    # --- shared user/home config via home-manager ---
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    # OMP coding agent (omp.sh): per-user home-manager install instead of a
    # system package group. The upstream module (flake input `omp`) provides
    # programs.omp, which owns ~/.omp/agent/config.yml — see common/home.nix.
    home-manager.sharedModules = [ omp.homeManagerModules.default ];
    # Rolling set for per-user packages that track nixpkgs-unstable (home.nix).
    home-manager.extraSpecialArgs = { inherit unstablePkgs; };
    home-manager.users.perryh = import ./home.nix;
  };
}
