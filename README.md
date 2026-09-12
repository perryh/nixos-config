# nixos-config

Multi-host NixOS config using flakes. Every host shares `common/` (users,
package groups, services, home-manager) so package versions stay identical
machine to machine; per-host files hold hostname + hardware specifics.

## Layout

- `flake.nix` — pins `nixpkgs` (release branch) + home-manager; `flake.lock`
  is the version pin. Upgrade on purpose:
  `nix flake lock --update-input nixpkgs`, rebuild all hosts, commit.
- `common/common.nix` — shared users, services, networking, home-manager
  wiring, and the `perry.systemGroups` selector.
- `common/pkg-groups.nix` — named package groups (`dev`, `containers`,
  `browsers`, `graphics`, `media`, `office`). A host picks its set with
  `perry.systemGroups`; default is all of them. Headless servers drop the GUI
  groups (see below).
- `common/home.nix` — shared user config via home-manager (zsh, git identity,
  ripgrep/fzf/eza).
- `pkgs/` — repo-local derivations for packages not in nixpkgs (currently
  `herdr`), applied via `nixpkgs.overlays` in `common/common.nix`.
- `hosts/<name>.nix` — per-host: hostname, boot loader, laptop/desktop
  specifics, and `perry.systemGroups` for that machine.
- `hosts/<name>-hardware.nix` — per-host boot/filesystem/disk. Regenerate with
  `sudo nixos-generate-config` and copy over; never hand-edit.

## Package groups

`perry.systemGroups` selects which named groups to install (default = all,
so a desktop needs no assignment):

```nix
# desktop — all groups (the default; nothing to set)

# headless server — no GUI
perry.systemGroups = [ "dev" "containers" ];
```

Groups:

| group        | packages                                            |
|--------------|-----------------------------------------------------|
| `dev`        | git, herdr                                          |
| `containers` | docker                                              |
| `browsers`   | firefox, brave, google-chrome                       |
| `graphics`   | gimp, darktable, imagemagick                        |
| `media`      | ffmpeg, mpv, vlc                                    |
| `office`     | libreoffice                                         |

Selecting `containers` also enables the `docker` daemon and adds the user to
the `docker` group; selecting `browsers` also enables the `firefox` module.

## First boot on a machine

1. Clone this repo (flakes are enabled by default on 25.05+).
2. `sudo nixos-generate-config` → copy `/etc/nixos/hardware-configuration.nix`
   into the repo as `hosts/<name>-hardware.nix`.
3. No password setup needed: `users.mutableUsers` (default) merges with
   existing accounts and leaves existing passwords alone. (For a brand-new
   user, set `hashedPassword`.)
4. Create `hosts/<name>.nix` (copy one) and add
   `nixosConfigurations.<name> = mkHost "<name>";` in `flake.nix`.
5. `sudo nixos-rebuild switch --flake <repo-path>#<name>`.

First build compiles the whole closure — takes a while. With a flake,
`/etc/nixos/configuration.nix` is left as-is; the flake in this repo is the
single source of truth.

## Adding a new host

1. Copy `hosts/perry-eb.nix` + `hosts/perry-eb-hardware.nix` to the new name.
2. Add `nixosConfigurations.<name> = mkHost "<name>";` in `flake.nix`.
3. Generate hardware on the machine, deploy, commit.

## Updating a package not in nixpkgs

Repo-local derivations live in `pkgs/`. Each is an overlay added in
`common/common.nix` (`nixpkgs.overlays`) and then referenced by name in a
package group. See `pkgs/herdr.nix` for the pattern — bump the version, url,
and hash, then rebuild.
