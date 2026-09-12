# Shared across ALL hosts — anything that should be identical on every machine.
{ pkgs, ... }: {

  time.timeZone = "America/Los_Angeles";

  # --- shared user account ---
  # Note: if a user doesn't exist on a host yet, initialHash = "" fails the
  # rebuild ("has no password hash") — set it from
  # `getent shadow perryh | cut -d: -f2` in that case.
  users.users.perryh = {
    isNormalUser = true;
    initialHash = "";
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
