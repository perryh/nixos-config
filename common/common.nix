# Shared across ALL hosts — anything that should be identical on every machine.
# Desktop/GUI-related options live here too, so every machine gets the same
# stack; override in hosts/<name>.nix if a machine differs (e.g. headless).
{ config, pkgs, ... }: {

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
  environment.systemPackages = with pkgs; [
    git
    gh
    neovim
    curl
    jq
  ];

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
  programs.firefox.enable = true;

  # --- shared user/home config via home-manager ---
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.perryh = import ./home.nix;
}
