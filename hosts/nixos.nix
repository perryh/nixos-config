# nixos (laptop) — per-host: hostname, power, display, bluetooth, etc.
{ ... }: {
  networking.hostName = "nixos";

  # --- laptop-only stuff ---
  services.bluetooth.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";
  services.upower.enable = true;

  # laptop-only user config:
  home-manager.users.perryh = {
    # add laptop-specific home-manager config here
  };
}
