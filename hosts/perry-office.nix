# perry-office (desktop) — per-host: hostname, power, display, bluetooth, etc.
{ config, pkgs, ... }: {
  networking.hostName = "perry-office";

  # Desktop GUI apps, language toolchains (and herdr, which only exists in
  # unstable) track nixpkgs-unstable for the latest versions; the OS and
  # everything else stay on the stable 26.05 pin.
  perry.unstableGroups = [ "browsers" "terminals" "chat" "ai" "langs" "dev-gui" "remote" "dev" ];

  # --- boot loader: systemd-boot (matches the installer's UEFI setup) ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- GPU: RTX 3060 (Ampere, 10de:2544) — proprietary userspace, open
  # kernel module (Ampere+). nvidia-smi ships with the driver package and
  # lands on PATH via hardware.nvidia. Runs the shared latest kernel like
  # every other host: stable 26.05's newest driver (595.71.05) predates
  # kernel 7.2 (DRM atomic refactor + strncpy removal), so we take the
  # newer 595.99.02 point release — already packaged on nixpkgs-unstable,
  # rebuilt here through stable's mkDriver against our pinned kernel.
  # Drop this override once 26.05 ships >= 595.99.02. ---
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "595.99.02";
    sha256_64bit = "sha256-6HR3lYv3YwcFSTJL1a1slI66btIQ5EAFs+/4SUD24ew=";
    sha256_aarch64 = "sha256-CCqHZTN2KNOZ4yZp2rDcuRJp9pHfRw47k4m4dWnS/2w=";
    openSha256 = "sha256-T36x/jx8yQ8l3LFp1rZIrTfcSwbGy8YSAvXOUSptpb4=";
    settingsSha256 = "sha256-GYCcnxfKPrTCrsmd25sMyzfC5cqJQJx0c31haooyTYM=";
    persistencedSha256 = "sha256-VyKtF/HdHPQrHHK6opSO69M72LmnGZtauuchj9uuje8=";
  };
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true; # required for Wayland/modern Plasma
    open = true;
    nvidiaSettings = true; # nvidia-settings GUI
  };

  # --- host-specific hardware services ---
  hardware.bluetooth.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";
  services.upower.enable = true;

  # Host-specific user config:
  home-manager.users.perryh = {
    # Add perry-office-specific home-manager config here
  };
}
