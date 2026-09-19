# nixos-config

Multi-host NixOS flake config (public: `perryh/nixos-config`, branch `main`).
All hosts share `common/` so package versions stay identical machine to
machine; per-host files hold hostname + hardware. Configured hosts: `perry-eb`
(laptop, tailscale 100.90.212.18 — this repo is checked out at
`~/git/nixos-config` there) and `perry-office` (desktop, RTX 3060 nvidia). A
Mac is covered by a standalone home-manager configuration, `perry-mac`
(aarch64-darwin, no NixOS host), which reuses `common/home.nix` verbatim.
No CI, no test suite, no linter — nix parse/eval is the check.

## Layout
- `flake.nix` — pins nixpkgs `nixos-26.05`, home-manager `release-26.05`
  (follows the nixpkgs input), the `omp` flake (module only — see
  `common/home.nix`), and `nixpkgs-unstable` (rolling branch, used ONLY for
  `perry.unstableGroups` — never for the OS). `mkHost "<name>"` wires common +
  host + hardware and passes `unstablePkgs` (unstable + `allowUnfree` + the
  `pkgs/` overlays) through `specialArgs`. `homeConfigurations.perry-mac` is
  the darwin entry point, with its own darwin pkgs imports + home-manager CLI.
- `common/common.nix` — shared users, services, desktop stack (Plasma 6/sddm),
  home-manager wiring, and the `perry.systemGroups` / `perry.unstableGroups`
  options. Applies the `pkgs/` overlay to the stable set, and wires the
  group-keyed side effects: `containers` → docker daemon + docker group,
  `browsers` → firefox module (package follows the group's source),
  `backup` → `services.restic.backups`.
- `common/pkg-groups.nix` — the named groups. Headless-safe: `core`
  (gh/neovim/vim/curl/jq), `dev`, `net`, `langs`, `ai`, `containers`,
  `tools`, `backup`. Desktop-only: `browsers`, `graphics`, `media`, `office`,
  `dev-gui`, `remote`, `terminals`, `chat`. `environment.systemPackages` is
  built entirely from groups — never list bare packages there (the only
  non-group user packages today are `users.users.perryh.packages`). Hosts take
  whole groups from `nixpkgs-unstable` via `perry.unstableGroups`
  (default `[]`); such a group is removed from the stable set and installed
  from unstable exactly once.
- `common/home.nix` — shared home-manager user config: git identity, zsh +
  oh-my-zsh, `programs.omp` settings, the custom GGPC provider rendered into
  `~/.omp/agent/models.yml` by `home.file`, and the per-user
  `unstablePkgs.herdr`.
- omp (oh-my-pi, omp.sh) is NOT a package group: it is installed per-user via
  home-manager — `programs.omp` in `common/home.nix`, package from
  `nixpkgs-unstable`, module from the `omp` flake input. `programs.omp.settings`
  overwrite `~/.omp/agent/config.yml` (as a writable copy) on every switch,
  so edits made inside omp are lost on the next switch — same for
  `models.yml`; change settings in `common/home.nix` instead.
- `pkgs/` — repo-local overlays of packages not in nixpkgs (currently `dsh`,
  a `buildNpmPackage` from the published npm tarball: prebuilt `lib/`, a
  committed lockfile, and the refresh recipe in `pkgs/dsh/default.nix`).
  Overlays must be applied to BOTH pkgs sets: stable via `nixpkgs.overlays` in
  common.nix, unstable via `overlays` in the flake.nix `unstablePkgs` import.
- `hosts/<name>.nix` — per-host: hostname, `perry.unstableGroups`, loader,
  NFS mounts, laptop/desktop specifics (perry-office overrides the nvidia
  driver package).
- `hosts/<name>-hardware.nix` — generated disk/luks layout; never hand-edit.
- `hosts/<name>.restic-backup.local.nix` — optional and gitignored
  (`*.local.nix`): an attrset of restic entries, imported only when the
  `backup` group is on. Each entry needs exactly one of
  `repository`/`repositoryFile`/`environmentFile` plus `passwordFile`.
  Secrets never enter the repo.

## Commands (verified)
- Deploy on the host: `sudo nixos-rebuild switch --flake ~/git/nixos-config#perry-eb`
  (`#perry-office` for the desktop).
- Mac: `home-manager switch --flake ~/git/nixos-config#perry-mac` (the CLI
  itself is installed into the profile by that config).
- Upgrade nixpkgs: `nix flake lock --update-input nixpkgs`, then rebuild all
  hosts and commit `flake.lock` (the lock file is the version pin). Refresh
  unstable-tracked groups: `nix flake update nixpkgs-unstable`; the omp module
  pin separately: `nix flake update omp`.
- Syntax gate (cheap — always run): `nix-instantiate --parse <file.nix>`
- Eval check (the real gate — parse catches syntax only; eval catches type
  errors and wrong attr names):
  `nix eval .#nixosConfigurations.<host>.config.environment.systemPackages --apply 'p: builtins.length (builtins.filter (x: x ? pname) p)'`
  The lambda must FORCE the elements: `--apply 'p: builtins.length p'` and
  `--apply 'p: 1'` both report success when an entry is not a `package`
  (verified against the locked 26.05 lib). Group side effects, e.g.
  `nix eval .#nixosConfigurations.<host>.config.services.restic.backups`.
  Single version: `nix eval .#nixosConfigurations.<host>.pkgs.<app>.version`
- Hardware changed: `sudo nixos-generate-config`, then
  `cp /etc/nixos/hardware-configuration.nix hosts/<name>-hardware.nix`
- Skills hold the detailed recipes: `nixos-config-pkg-verify` and
  `nixos-config-group-verify` (26.05 attr-name traps, attr-vs-`pname` names,
  forcing each element).

## Conventions
- Shared packages go into a group in `common/pkg-groups.nix` —
  `environment.systemPackages` holds only the group expansion (no bare
  packages). Side effects tie to groups: `containers` → docker daemon +
  docker group; `browsers` → firefox module; `backup` → restic service.
- `perry.unstableGroups` (same group names) takes groups from the rolling
  `nixpkgs-unstable` input (pinned in `flake.lock`); they're removed from the
  stable set and installed exactly once. Both hosts currently track
  `[ "browsers" "terminals" "chat" "ai" "langs" "dev-gui" "remote" ]`.
- `herdr` (in the `ai` group, with opencode and repo-local dsh) exists ONLY in
  unstable — hosts on the all-groups default must list it in
  `perry.unstableGroups` (both do); selecting it from the stable set throws a
  clear error.
- Headless hosts set `perry.systemGroups = [ "core" "dev" "containers" ]`
  (default = all groups; `core` = gh/neovim/vim/curl/jq).
- New host: copy `hosts/perry-eb*.nix` to the new name, add
  `nixosConfigurations."<name>" = mkHost "<name>";` (name quoted) in flake.nix.
- Any module defining top-level `options` (like common.nix) must put every
  config attr under an explicit `config = { ... }`.
- Prebuilt binary in `pkgs/`: `final.runCommand` + `fetchurl`; the SRI hash is
  base64 of the raw sha256 bytes. Never mkDerivation for a bare executable.
  (No such packages currently — herdr was upstreamed to nixpkgs; its
  repo-local overlay was removed in favor of the `ai` group.)
- `perryh`'s `openssh.authorizedKeys` mirror `github.com/perryh.keys` — keep
  in sync when keys change there.
- Secrets only in gitignored `*.local.nix` / `local/` (the repo is public).
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
- perry-office overrides `hardware.nvidia.package` with a `mkDriver` 595.99.02
  point release (stable 26.05's driver predates kernel 7.2); drop the override
  once 26.05 ships >= 595.99.02.
- "Git tree is dirty" warning after a rebuild is harmless (uncommitted
  flake.lock). `flake.lock` may end up root-owned after sudo rebuilds —
  regenerate in a `cp -r` of the repo under /tmp, then swap the file back.
- Sudo rebuilds can leave root-owned files in `.git` too (e.g.
  `.git/objects/<2-hex>`), after which git fails with "insufficient permission
  for adding an object to repository database". Without sudo, fix by renaming
  the root-owned dir in place (`mv .git/objects/XX .git/objects/XX-root-owned`)
  — a same-filesystem rename needs write permission only on the parent.
- Remote work on the host: no passwordless sudo over SSH (rebuild on the
  laptop), python3 may be absent (keep one-liners pure nix), and avoid
  nix `${...}` interpolation in commands sent over ssh (the remote shell
  expands it first).
- Evals are memory-hungry here (a broad one has been killed): keep `nix eval`
  to a single attribute, and to check whether an attr exists at a pinned rev,
  probe that rev's nixpkgs source (the `fetchTarball`/store-path trick) rather
  than evaluating a whole host or home configuration.
