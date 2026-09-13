# nixos-config

Multi-host NixOS config using flakes. Every host shares `common/` (users,
package groups, services, home-manager) so package versions stay identical
machine to machine; per-host files hold hostname + hardware specifics.

## Layout

- `flake.nix` — pins `nixpkgs` (release branch) + home-manager; `flake.lock`
  is the version pin. Upgrade on purpose:
  `nix flake lock --update-input nixpkgs`, rebuild all hosts, commit.
  Also pins `nixpkgs-unstable` (rolling) for groups listed in
  `perry.unstableGroups`; refresh with `nix flake update nixpkgs-unstable`.
- `common/common.nix` — shared users, services, networking, home-manager
  wiring, the `perry.systemGroups` selector, and the `perry.unstableGroups`
  selector (same group names served from the rolling unstable branch).
- `common/pkg-groups.nix` — named package groups (`core`, `dev`, `containers`,
  `browsers`, `graphics`, `media`, `office`, `terminals`, `chat`, `ai`). A
  host picks its set with `perry.systemGroups`; default is all of them.
  Headless servers drop the GUI groups (see below). `ai` (herdr) is
  nixpkgs-unstable-only — it must be in `perry.unstableGroups`, not the
  stable set.
- `common/home.nix` — shared user config via home-manager (zsh, git identity,
  ripgrep/fzf/eza).
- `pkgs/` — reserved for repo-local derivations of packages not in nixpkgs
  (currently empty; herdr is now upstream). Pattern when one is needed: an
  overlay in `pkgs/<name>.nix` added to `nixpkgs.overlays` in
  `common/common.nix`, referenced by name in a group.
- `hosts/<name>.nix` — per-host: hostname, boot loader, laptop/desktop
  specifics, and `perry.systemGroups` for that machine.
- `hosts/<name>-hardware.nix` — per-host boot/filesystem/disk. Regenerate with
  `sudo nixos-generate-config` and copy over; never hand-edit.

## Package groups

`perry.systemGroups` selects which named groups to install (default = all,
so a desktop needs no assignment):

```nix
# desktop — all groups including core (the default; nothing to set)

# headless server — no GUI, keep the base tools
perry.systemGroups = [ "core" "dev" "containers" ];
```

Groups:

| group        | packages                                            |
|--------------|-----------------------------------------------------|
| `core`       | gh, neovim, curl, jq                                |
| `dev`        | git                                                 |
| `containers` | docker                                              |
| `browsers`   | firefox, brave, google-chrome                       |
| `graphics`   | gimp, darktable, imagemagick                        |
| `media`      | ffmpeg, mpv, vlc                                    |
| `office`     | libreoffice                                         |
| `terminals`  | ghostty                                             |
| `chat`       | vesktop, signal-desktop, slack                      |
| `ai`         | herdr, opencode (see below)                         |

Selecting `containers` also enables the `docker` daemon and adds the user to
the `docker` group; selecting `browsers` also enables the `firefox` module.

## Unstable groups

A host can take whole groups from the rolling `nixpkgs-unstable` branch
instead of the stable pin, while the OS and everything else stay on the
release branch:

```nix
# hosts/<name>.nix
perry.unstableGroups = [ "browsers" "terminals" "chat" "ai" ];
```

The group is then installed exactly once, from unstable (its stable copy is
dropped). Refresh those apps with `nix flake update nixpkgs-unstable` +
rebuild; remove a group from the list to return it to the stable pin.
Note the `ai` group (herdr) exists only in unstable — hosts that don't list
it in `perry.unstableGroups` get a clear error if the stable set includes it.

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

## Packages not in nixpkgs

When a package isn't in nixpkgs at all, add a repo-local derivation under
`pkgs/<name>.nix` as an overlay (wired into `nixpkgs.overlays` in
`common/common.nix`, referenced by name in a group). Prebuilt release
binaries: `final.runCommand` + `fetchurl` (SRI hash = base64 of the raw
sha256 bytes) — never `mkDerivation` for a bare executable. (Currently no
such packages: herdr was upstreamed into nixpkgs and the repo-local overlay
was removed.)
