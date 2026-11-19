# perry-eb (laptop) — per-host: hostname, power, display, bluetooth, etc.
{ pkgs, ... }: {
  networking.hostName = "perry-eb";

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

  # --- NFS: definer4 (Unraid NAS, 100.105.112.61 over tailscale) ---
  # Unraid serves NFSv4 read-only, so pin vers=3 (rw; needs local
  # rpcbind/statd, provided by supportedFilesystems). Shares mount on
  # first access and unmount after 10 idle minutes (laptop-friendly).
  boot.supportedFilesystems = [ "nfs" ];
  fileSystems."/mnt/definer4/perry" = {
    device = "definer4:/mnt/user/perry";
    fsType = "nfs";
    options = [ "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "vers=3" ];
  };
  fileSystems."/mnt/definer4/media" = {
    device = "definer4:/mnt/user/media";
    fsType = "nfs";
    options = [ "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "vers=3" ];
  };
  # --- laptop-only stuff ---
  hardware.bluetooth.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";
  services.upower.enable = true;

  # --- steam ---
  # Radeon 890M: mesa/radv out of the box — no driver config needed. The
  # programs.steam module (at our 26.05 pin f684076) already does the wiki's
  # manual setup: hardware.graphics.enable + enable32Bit (the
  # "glXChooseVisual failed" fix), steam-hardware gamepad udev rules, and
  # installs steam + steam-run (FHS env for non-steam proprietary games).
  programs.steam = {
    enable = true;
    # GE-Proton as a declarative compat tool (GE-Proton11-1 at this pin; the
    # required steamcompattool output is present) — shows up per-game in
    # Steam's compatibility menu, so no protonup-qt.
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    # winetricks for Proton prefixes; the module installs it wired to the
    # same compat-tools path.
    protontricks.enable = true;
    # MangoHud overlay on every game (the module's documented package
    # pattern). "1", not `true`: mangohud's implicit Vulkan layer is gated by
    # enable_environment MANGOHUD=1 at loader level.
    package = pkgs.steam.override { extraEnv.MANGOHUD = "1"; };
  };
  # Feral GameMode daemon — games request CPU-governor/priority optimizations.
  programs.gamemode.enable = true;
  # MangoHud's Vulkan layer must be discoverable inside Steam's FHS env (which
  # appends /run/opengl-driver*/share to XDG_DATA_DIRS) and in pressure-vessel
  # containers — so it goes through the driver set, 64- and 32-bit.
  hardware.graphics = {
    extraPackages = [ pkgs.mangohud ];
    extraPackages32 = [ pkgs.pkgsi686Linux.mangohud ];
  };

  # --- memory: compressed RAM swap (zram) ---
  # Half of RAM as a zstd-compressed swap device (~15 GiB logical on this 32 GB
  # box, which loses a little to the 890M iGPU carve-out). The 8.8 G LUKS
  # partition in the hardware file stays as lower-priority overflow: zram's
  # default priority 5 beats the disk's -1, so zram fills first and the disk is
  # a last-resort safety net rather than the primary swap. 26.05 implements
  # this via services.zram-generator, which sets restartIfChanged = false — a
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

  # laptop-only user config:
  home-manager.users.perryh = {
    # add laptop-specific home-manager config here
  };
}
