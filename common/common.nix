# Shared across ALL hosts — anything that should be identical on every machine.
{ pkgs, ... }: {

  system.stateVersion = "26.05";
  time.timeZone = "America/Los_Angeles";

  # --- shared user account ---
  # perryh already exists on each host with a real password; with
  # users.mutableUsers (default) existing passwords are left untouched, so no
  # password option is needed here. For a brand-new user on a host, set
  # hashedPassword (or initialHashedPassword) instead.
  users.users.perryh = {
    isNormalUser = true;
  };

  # --- shared system packages (identical versions on every host) ---
  environment.systemPackages = with pkgs; [
    git
    gh
    neovim
    curl
    jq
  ];

  # --- shared user/home config via home-manager ---
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.perryh = import ./home.nix;

  # --- shared services ---
  services.openssh.enable = true;
}
