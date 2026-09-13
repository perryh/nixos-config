# nixos-config

Multi-host NixOS flake config (public: `perryh/nixos-config`, branch `main`).
All hosts share `common/` so package versions stay identical machine to
machine; per-host files hold hostname + hardware. One host online: `perry-eb`
(laptop, tailscale 100.90.212.18, repo at `~/git/nixos-config` there).
No CI, no test suite, no linter — nix eval/parse is the check.

## Layout
- `flake.nix` — pins nixpkgs `nixos-26.05` + home-manager `release-26.05`
  (follows the nixpkgs input); `mkHost "<name>"` wires common + host + hardware.
- `common/common.nix` — shared users, services, desktop stack, home-manager,
  and the `perry.systemGroups` option.
- `common/pkg-groups.nix` — named groups: `core` (gh/neovim/curl/jq), `dev`,
  `containers`, `browsers`, `graphics`, `media`, `office`, `terminals`,
  `chat`. `environment.systemPackages` is built entirely from groups — never
  list bare packages there. Hosts can take whole groups from
  `nixpkgs-unstable` via `perry.unstableGroups` (default `[]`); the group is
  then installed only from unstable.
- `common/home.nix` — shared home-manager user config (git identity lives here).
- `pkgs/<name>.nix` — repo-local overlays for packages not in nixpkgs (herdr).
- `hosts/<name>.nix` — per-host: hostname, loader, laptop/desktop specifics.
- `hosts/<name>-hardware.nix` — generated disk/luks layout; never hand-edit.

## Commands (verified)
- Deploy on the host: `sudo nixos-rebuild switch --flake ~/git/nixos-config#perry-eb`
- Upgrade nixpkgs: `nix flake lock --update-input nixpkgs`, then rebuild all
  hosts and commit `flake.lock` (the lock file is the version pin). Refresh
  unstable-tracked groups: `nix flake update nixpkgs-unstable`.
- Syntax gate: `nix-instantiate --parse <file.nix>`
- Eval check: `nix eval .#nixosConfigurations.perry-eb.pkgs.<app>.version`
- Hardware changed: `sudo nixos-generate-config`, then
  `cp /etc/nixos/hardware-configuration.nix hosts/<name>-hardware.nix`

## Conventions
- Shared packages go into a group in `common/pkg-groups.nix` —
  `environment.systemPackages` holds only the group expansion (no bare
  packages). Side effects tie to groups: `containers` → docker daemon +
  docker group; `browsers` → firefox module.
- Headless hosts set `perry.systemGroups = [ "core" "dev" "containers" ]`
  (default = all groups; `core` = gh/neovim/curl/jq).
- New host: copy `hosts/perry-eb*.nix` to the new name, add
  `nixosConfigurations."<name>" = mkHost "<name>";` (name quoted) in flake.nix.
- Any module defining top-level `options` (like common.nix) must put every
  config attr under an explicit `config = { ... }`.
- Prebuilt binary in `pkgs/`: `final.runCommand` + `fetchurl`; the SRI hash is
  base64 of the raw sha256 bytes. Never mkDerivation for a bare executable.
  (No such packages currently — herdr was upstreamed to nixpkgs; its
  repo-local overlay was removed in favor of the `ai` group.)
- Commits: imperative, short, optional `scope:` prefix
  (e.g. `chat: add slack`, `herdr: use runCommand`). Git identity comes from
  home-manager's git config — don't pass `-c user.name/-c user.email`.

## Pitfalls
- Verify module options against the locked rev in `flake.lock`, not branch
  tip; module paths get reorganized between releases.
- 26.05 renames that hard-error: `users.*.initialHashedPassword` (not
  `initialHash`), `hardware.bluetooth` (not `services.bluetooth`),
  home-manager `programs.zsh.setOptions` (not `shellOptions`),
  `programs.git.settings` (not `userName/userEmail`); `gitAndTools` removed
  (plain `git`).
- `dockerTools` is a helper attrset, not a package — adding it to
  `environment.systemPackages` fails with "not of type `package`".
- home-manager symlinks `~/.config/*` into the read-only store — manual writes
  (e.g. `git config --global`) fail EROFS; set the value in home.nix, rebuild.
- Passwords never in the repo (it is public): `users.mutableUsers` (default)
  keeps local passwords; brand-new users need `hashedPassword`.
- First full-closure build (Plasma + browsers + office) is very long — don't
  re-run on an apparent stall.
- "Git tree is dirty" warning after a rebuild is harmless (uncommitted
  flake.lock). `flake.lock` may end up root-owned after sudo rebuilds —
  regenerate in a `cp -r` of the repo under /tmp, then swap the file back.
- Remote work on the host: no passwordless sudo over SSH (rebuild on the
  laptop), python3 may be absent (keep one-liners pure nix), and avoid
  nix `${...}` interpolation in commands sent over ssh (the remote shell
  expands it first).
