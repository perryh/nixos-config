# Shared across ALL hosts — anything that should be identical on every machine.
{ pkgs, ... }: {

  time.timeZone = "America/Los_Angeles";

  # --- shared user account ---
  users.users.perry = {
    isNormalUser = true;
    initialHash = ""; # run `sudo passwd perry` once before the first flake build
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
  home-manager.users.perry = import ./home.nix;

  # --- shared services ---
  services.openssh.enable = true;
}
