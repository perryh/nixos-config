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

1. Clone this repo to `~/nix-config` (flakes are enabled by default on 25.05+)
2. `sudo nixos-generate-config` → move `/etc/nixos/hardware-configuration.nix`
   into the repo as `hosts/<name>-hardware.nix`
3. No password setup needed: `users.mutableUsers` (default) merges with
   existing accounts and leaves existing passwords alone. (For a brand-new
   user, set `hashedPassword`.)
4. `sudo nixos-rebuild switch --flake ~/nix-config#<name>`

First build compiles the whole closure — takes a while. After that,
`/etc/nixos/configuration.nix` becomes a symlink into the repo; the repo is
the single source of truth.

## Adding a new host

1. Copy `hosts/nixos.nix` + `hosts/nixos-hardware.nix` to the new name.
2. Add `nixosConfigurations.<name> = mkHost "<name>";` in `flake.nix`.
3. Generate hardware on the machine, deploy, commit.
