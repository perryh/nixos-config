# Shared across ALL hosts — anything that should be identical on every machine.
# Desktop/GUI-related options live here too, so every machine gets the same
# stack; override in hosts/<name>.nix if a machine differs (e.g. headless).
#
# Package groups: pick per-host which named groups (common/pkg-groups.nix) to
# install via perry.systemGroups. Default = all groups (desktop). A headless
# server would set:  perry.systemGroups = [ "core" "dev" "containers" ];
{ config, pkgs, lib, unstablePkgs, ... }:

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
    # the same overlays so groups can reference them from either source.
    nixpkgs.overlays = [
      (import ../pkgs/dsh)
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

    # Latest kernel
    boot.kernelPackages = pkgs.linuxPackages_latest;

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
      # Hermes agent access (perry-mini / vm2)
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO6SOPUNcvb91Tq6t06pEMWp8KeV3btxtpoY0dEMduPC perry.huang@gmail.com"
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
    home-manager.users.perryh = import ./home.nix;
  };
}
