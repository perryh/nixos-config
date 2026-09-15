# perry-eb (laptop) — per-host: hostname, power, display, bluetooth, etc.
{ ... }: {
  networking.hostName = "perry-eb";

  # Desktop GUI apps, language toolchains (and herdr, which only exists in
  # unstable) track nixpkgs-unstable for the latest versions; the OS and
  # everything else stay on the stable 26.05 pin.
  perry.unstableGroups = [ "browsers" "terminals" "chat" "ai" "langs" ];

  # --- boot loader: systemd-boot (matches the installer's UEFI setup) ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- laptop-only stuff ---
  hardware.bluetooth.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";
  services.upower.enable = true;

  # laptop-only user config:
  home-manager.users.perryh = {
    # add laptop-specific home-manager config here
  };
}
