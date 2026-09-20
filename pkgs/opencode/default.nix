# OpenCode 2 CLI (https://opencode.ai) — not in nixpkgs: the stable 26.05 pin
# carries opencode 1.15.10 and the rolling pin 1.18.x, so v2 is packaged here
# from upstream's own nix recipe, which ships inside its source tree
# (nix/node_modules.nix + nix/opencode.nix + nix/hashes.json).
#
# Why build from source instead of using the prebuilt platform binaries upstream
# publishes (npm @opencode/cli-linux-x64 / -darwin-arm64 — what
# opencode.ai/v2/install downloads): those are bun single-file executables whose
# bundle lives in a trailer appended to the ELF, and patchelf (i.e.
# autoPatchelfHook) rewrites the file such that the binary silently degrades to
# plain `bun` (verified: `--version` prints the bun version and the help text is
# bun's). Compiling with nixpkgs' bun bakes the nix interpreter in from the
# start — which is how nixpkgs packages opencode 1.x too.
#
# Why the STABLE pkgs set (wired in common/common.nix, and in the perry-mac pkgs
# import in flake.nix): the per-system node_modules fixed-output hash in
# upstream's nix/hashes.json was computed with bun 1.3.13 — the version this
# repo's 26.05 pin carries. The rolling pin's bun 1.4.2 installs a different
# tree (verified: FOD hash mismatch), and recomputing that hash is not possible
# for aarch64-darwin from the Linux hosts. The opencode version is pinned right
# here, so every machine still gets the identical build.
#
# Refresh recipe (new upstream vX.Y.Z):
#   1. bump `version`, set `rev` to the tag's short commit
#   2. set `hash = prev.lib.fakeHash`, build, copy the reported "got: sha256-..."
#   3. if the node_modules FOD then fails with a hash mismatch, upstream's bun
#      moved: recompute nix/hashes.json (fakeHash → build → paste) — that needs a
#      builder per system, i.e. the Mac for aarch64-darwin.
final: prev:
let
  version = "2.0.10";
  # Short commit of the v2.0.10 tag; only feeds the "+<rev>" version suffix
  # upstream's recipe appends (without it the version renders as "2.0.10+dirty").
  rev = "b8cedc1";

  src = prev.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-zQFTqF470y1mI4h4Uv18TGqXP2O/QXWAIf+Qoa4I8kk=";
  };
in
{
  # Upstream's derivation: bun-compiled CLI from packages/cli, wrapped with
  # ripgrep (grep tool) and — on Linux — libwayland (OpenTUI dlopens it for
  # clipboard images). node_modules also supplies version + src, so the version
  # comes from the source tree instead of a second pin here.
  #
  # OPENCODE_DISABLE_AUTOUPDATE is what nixpkgs sets for its own opencode
  # package: the CLI's updater otherwise downloads an upstream prebuilt and runs
  # it — broken on NixOS (no /lib64 loader, see the header) and unmanaged in any
  # case, since the version here is what the repo pins. `opencode upgrade` still
  # works explicitly; bump `version` above to move forward.
  opencode = (prev.callPackage "${src}/nix/opencode.nix" {
    node_modules = prev.callPackage "${src}/nix/node_modules.nix" { inherit rev; };
  }).overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/opencode --set OPENCODE_DISABLE_AUTOUPDATE true
    '';
  });
}
