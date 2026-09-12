# nixos (laptop) — per-host: hostname, power, display, bluetooth, etc.
{ ... }: {
  networking.hostName = "nixos";

  # --- boot loader: UEFI + LUKS btrfs root, ESP at /boot ---
  boot.loader.grub = {
    enable = true;
    # Whole NVMe disk (for the MBR / legacy fallback). 26.05 no longer
    # auto-detects this.
    device = "/dev/nvme0n1";
    efiSupport = true;
  };
  # Allow GRUB to register itself with the UEFI boot variables.
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
