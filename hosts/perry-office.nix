# perry-office (desktop) — per-host: hostname, power, display, bluetooth, etc.
{ ... }: {
  networking.hostName = "perry-office";

  # Desktop GUI apps, language toolchains (and herdr, which only exists in
  # unstable) track nixpkgs-unstable for the latest versions; the OS and
  # everything else stay on the stable 26.05 pin.
  perry.unstableGroups = [ "browsers" "terminals" "chat" "ai" "langs" "dev-gui" ];

  # --- boot loader: systemd-boot (matches the installer's UEFI setup) ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- NFS: definer4 (Unraid NAS, 100.105.112.61 over tailscale) ---
  # Unraid serves NFSv4 read-only, so pin vers=3 (rw; needs local
  # rpcbind/statd, provided by supportedFilesystems). Shares mount on
  # first access and unmount after 10 idle minutes (laptop-friendly).
  boot.supportedFilesystems = [ "nfs" ];
  #fileSystems."/mnt/definer4/perry" = {
  #  device = "definer4:/mnt/user/perry";
  #  fsType = "nfs";
  #  options = [ "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "vers=3" ];
  #};
  #fileSystems."/mnt/definer4/media" = {
  #  device = "definer4:/mnt/user/media";
  #  fsType = "nfs";
  #  options = [ "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "vers=3" ];
  #};
  # --- laptop-only stuff ---
  hardware.bluetooth.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";
  services.upower.enable = true;

  # laptop-only user config:
  home-manager.users.perryh = {
    # add laptop-specific home-manager config here
  };
}
