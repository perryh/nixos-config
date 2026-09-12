# Hardware config for nixos (laptop).
#
# DO NOT hand-edit. On THIS machine:
#   sudo nixos-generate-config
#   sudo cp /etc/nixos/hardware-configuration.nix ~/git/nix-config/hosts/nixos-hardware.nix
# Then commit. This file carries the real disk layout (fileSystems, boot
# parameters, file systems) that boot.loader.grub.devices needs to install.
# Keep it out of the shared modules so other hosts don't import it.
{ ... }: {
  # placeholder — replace with the real generated file
}
