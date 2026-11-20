# perry-office (desktop) — per-host: hostname, power, display, bluetooth, etc.
{ config, pkgs, ... }: {
  networking.hostName = "perry-office";

  # Desktop GUI apps and language toolchains track nixpkgs-unstable for the
  # latest versions; the OS and everything else stay on the stable 26.05 pin.
  # `browsers` deliberately stays on the stable pin: Brave's Qt shim loads the
  # session's Qt plugins from QT_PLUGIN_PATH, so it must be built against the
  # same Qt as Plasma (unstable's Brave links Qt 6.12 and aborts on 26.05's
  # Qt 6.11).
  perry.unstableGroups = [ "terminals" "chat" "langs" "dev-gui" "remote" "dev" ];

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

  # --- storage: btrfs transparent compression ---
  # The generated hardware entry for / sets no mount options, and
  # fileSystems.*.options is a merging nonEmptyListOf, so this appends rather
  # than replaces. Only new writes compress; older data stays as-is.
  fileSystems."/".options = [ "compress=zstd:3" ];

  # --- memory: compressed RAM swap (zram) ---
  # Half of RAM as a zstd-compressed swap device. The LUKS swap partition in
  # the hardware file stays as lower-priority overflow: zram's default
  # priority 5 beats the disk's -1, so zram fills first and the disk is a
  # last-resort safety net rather than the primary swap. 26.05 implements this
  # via services.zram-generator, which sets restartIfChanged = false — a
  # rebuilt switch leaves the live device alone, so sizing changes need a
  # reboot. Don't enable boot.zswap here too: the two are mutually exclusive.
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;
  # swappiness 100 is the "swap and page cache cost the same" point on the
  # post-5.8 0-200 scale (kernel default 60 assumes swap is slow disk I/O; see
  # admin-guide/sysctl/vm.rst for the derivation). page-cluster = 0 disables
  # swap readahead clustering, which buys nothing when the "read" is a RAM
  # copy. Both are runtime sysctls, so a switch applies them without a reboot
  # (unlike the zram sizing above).
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    "vm.page-cluster" = 0;
  };

  # Host-specific user config:
  home-manager.users.perryh = {
    # Add perry-office-specific home-manager config here
  };
}
