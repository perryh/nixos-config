# Shared across ALL hosts — anything that should be identical on every machine.
{ pkgs, ... }: {

  time.timeZone = "America/Los_Angeles";

  # --- shared user account ---
  users.users.perryh = {
    isNormalUser = true;
    # First switch on a host with an existing password:
  #   H=$(getent shadow perryh | cut -d: -f2)
    # then set initialHash = "$H"; below (private repo only!), or the
    # rebuild fails with "The user 'perryh' has no password hash".
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
