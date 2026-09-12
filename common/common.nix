# Shared across ALL hosts — anything that should be identical on every machine.
# Desktop/GUI-related options live here too, so every machine gets the same
# stack; override in hosts/<name>.nix if a machine differs (e.g. headless).
#
# Package groups: pick per-host which named groups (common/pkg-groups.nix) to
# install via perry.systemGroups. Default = all groups (desktop). A headless
# server would set:  perry.systemGroups = [ "dev" "containers" ];
{ config, pkgs, lib, ... }:

let
  groups = import ./pkg-groups.nix { inherit pkgs; };
  # `config` here is the final merged config, so host overrides to
  # perry.systemGroups (and its default) are visible.
  enabledGroups = map (g:
    groups.${g} or (throw (
      "perry.systemGroups: unknown group '${g}' (valid: "
      + lib.concatStringsSep ", " (lib.attrNames groups)
      + ")"
    ))
  ) config.perry.systemGroups;
in
{
  options.perry.systemGroups = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = lib.attrNames groups;
    example = [ "dev" "containers" ];
    description = "Which named package groups (common/pkg-groups.nix) to install. Headless hosts drop the GUI groups.";
  };

  config = {
    system.stateVersion = "26.05";
    time.timeZone = "America/Los_Angeles";

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
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [
        kdePackages.kate
      ];
      # Hermes agent access (perry-mini / vm2)
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO6SOPUNcvb91Tq6t06pEMWp8KeV3btxtpoY0dEMduPC perry.huang@gmail.com"
      ];
    };

    # --- shared system packages (identical versions on every host) ---
    # Base set is always present; named groups are selected by perry.systemGroups.
    # (git comes from gitAndTools in the "dev" group — no bare `git` needed.)
    environment.systemPackages =
      with pkgs; [
        gh
        neovim
        curl
        jq
      ]
      ++ builtins.concatLists enabledGroups;

    # --- networking ---
    networking.networkmanager.enable = true;
    services.tailscale.enable = true;

    # --- shared services ---
    services.openssh.enable = true;
    services.printing.enable = true;

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
    # Tied to the "browsers" group so headless hosts (which drop GUI groups)
    # don't still get a browser.
    programs.firefox.enable = lib.elem "browsers" config.perry.systemGroups;

    # --- shared user/home config via home-manager ---
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.perryh = import ./home.nix;
  };
}
