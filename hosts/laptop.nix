# Laptop-specific config (hostname, power, display, bluetooth, etc.)
{ ... }: {
  networking.hostName = "laptop"; # CHANGE to match the host you deploy this to

  # --- laptop-only stuff ---
  services.bluetooth.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";
  services.upower.enable = true;

  # laptop-only user config:
  home-manager.users.perry = {
    # add laptop-specific home-manager config here
  };
}
