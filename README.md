# perryh-nixos

Multi-host NixOS config using flakes. Every host shares `common/` (users,
system packages, home-manager) so package versions stay identical machine to
machine; per-host files hold hostname + hardware specifics.

## Layout

- `flake.nix` — pins `nixpkgs` (release branch) + home-manager; `flake.lock`
  is the version pin. Upgrade on purpose:
  `nix flake lock --update-input nixpkgs`, rebuild all hosts, commit.
- `common/common.nix` — shared users, system packages, home-manager wiring.
- `common/home.nix` — shared user config (zsh, git, ripgrep, ...).
- `hosts/<name>.nix` — per-host: hostname, laptop/desktop specifics.
- `hosts/<name>-hardware.nix` — per-host boot/filesystem/disk. Regenerate with
  `sudo nixos-generate-config` and copy over; never hand-edit.

## First boot on a machine

1. `echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf`
2. Clone this repo to `~/nix-config`
3. `sudo nixos-generate-config` → move `/etc/nixos/hardware-configuration.nix`
   into the repo as `hosts/<name>-hardware.nix`
4. `sudo passwd perry` (before the first flake build)
5. `sudo nixos-rebuild switch --flake ~/nix-config#<name>`

First build compiles the whole closure — takes a while. After that,
`/etc/nixos/configuration.nix` becomes a symlink into the repo; the repo is
the single source of truth.

## Adding a new host

1. Copy `hosts/laptop.nix` + `hosts/laptop-hardware.nix` to the new name.
2. Add `nixosConfigurations.<name> = mkHost "<name>";` in `flake.nix`.
3. Generate hardware on the machine, deploy, commit.
