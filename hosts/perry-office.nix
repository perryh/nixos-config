# perry-office (desktop) — per-host: hostname, power, display, bluetooth, etc.
{ pkgs, ... }: {
  networking.hostName = "perry-office";

  # Desktop GUI apps, language toolchains (and herdr, which only exists in
  # unstable) track nixpkgs-unstable for the latest versions; the OS and
  # everything else stay on the stable 26.05 pin.
  perry.unstableGroups = [ "browsers" "terminals" "chat" "ai" "langs" "dev-gui" ];

  # --- boot loader: systemd-boot (matches the installer's UEFI setup) ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- GPU: RTX 3070 Ti (Ampere, 10de:2544) — proprietary userspace, open
  # kernel module (Ampere+). nvidia-smi ships with the driver package and
  # lands on PATH via hardware.nvidia. ---
  # The nvidia module (595.71.05 in stable 26.05) does not compile against
  # kernel 7.2 (implicit strncpy decl), so this host overrides the shared
  # latest-kernel pin (common.nix) with the distro default that nixpkgs CI
  # builds nvidia against. Revisit when 26.05 carries a kernel-7-capable
  # driver.
  boot.kernelPackages = pkgs.linuxPackages;
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true; # required for Wayland/modern Plasma
    open = true;
    nvidiaSettings = true; # nvidia-settings GUI
  };

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
