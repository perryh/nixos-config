# OpenCode 2 CLI (https://opencode.ai) — not in nixpkgs: the locked stable 26.05
# pin carries opencode 1.15.10 and the rolling pin 1.18.x, so v2 is packaged
# here from the npm platform tarballs upstream's own installer resolves
# (@opencode/cli-<os>-<arch>; `curl -fsSL https://opencode.ai/v2/install | bash`
# reads opencode.ai/update/api/latest/cli/npm and then fetches exactly these).
#
# Why the prebuilt tarballs instead of upstream's in-tree nix recipe
# (nix/opencode.nix at the release tag, which compiles packages/cli with
# nixpkgs' bun — what nixpkgs itself does for opencode 1.x): that recipe's
# node_modules fixed-output hash is bun-version specific and per system, so the
# repo would have to pin one pkgs set's bun forever, and the aarch64-darwin hash
# cannot be recomputed (or even checked) from the Linux hosts. A published
# binary is platform-independent to package — one hash per system, no compiler,
# and every machine gets identical bytes.
#
# Why patchelf: the npm binary is a bun single-file executable linked against a
# generic /lib64/ld-linux-*.so.2, which NixOS does not have (stub-ld).
# --set-interpreter/--set-rpath touch only the ELF header and dynamic section;
# the JS bundle is an EOF trailer and survives that. It must survive: the CLI
# re-executes itself (`opencode serve --service`, and `upgrade`/`uninstall`), so
# running the untouched file through the nix glibc loader instead is not an
# option — the child execvp's the real file and dies with "error while loading
# shared libraries". installCheckPhase below fails the build if the bundle is
# ever damaged: a degraded binary prints bun's own version in `--version`.
#
# Refresh (new upstream vX.Y.Z, e.g. from
# https://opencode.ai/update/api/latest/cli/npm):
#   for t in linux-x64 linux-arm64 darwin-arm64 darwin-x64; do
#     nix store prefetch-file --json \
#       "https://registry.npmjs.org/@opencode/cli-$t/-/cli-$t-<version>.tgz" |
#       jq -r .hash
#   done
#   then bump `version` and the four hashes below. prefetch-file hashes any URL
#   from any machine, so the darwin hashes are checkable on Linux too.
final: prev:
let
  inherit (prev) lib;

  version = "2.0.24";

  # npm platform package name + SRI hash of its tarball, per system.
  targets = {
    x86_64-linux = {
      npmPlatform = "linux-x64";
      hash = "sha256-IbHuBoOEFAXWlUH8REgfjldS6Vvqcui47DHbzbEC5/g=";
    };
    aarch64-linux = {
      npmPlatform = "linux-arm64";
      hash = "sha256-nQzSv8Bg/Wwq/fbbaYN/hpDUao2DJ7uGRCGFHOAE9FM=";
    };
    aarch64-darwin = {
      npmPlatform = "darwin-arm64";
      hash = "sha256-fwPN/ZC/DORdSmbxvtfnZ+I7VGetGTqEVefG+7HquaE=";
    };
    x86_64-darwin = {
      npmPlatform = "darwin-x64";
      hash = "sha256-DJExlBPkfoP1D894GHjtFEspcr2JAe75L9qRQYAMTog=";
    };
  };

  system = prev.stdenv.hostPlatform.system;
  target = targets.${system} or (throw "opencode: no prebuilt binary for ${system}");

  # ripgrep backs the grep tool. On Linux OpenTUI dlopens wayland for clipboard
  # images (upstream's own recipe adds both). OPENCODE_DISABLE_AUTOUPDATE is
  # what nixpkgs sets for its opencode: without it the CLI downloads an upstream
  # prebuilt into ~/.opencode and runs that instead of this pinned build.
  wrapFlags = [
    "--prefix PATH : ${lib.makeBinPath [ prev.ripgrep ]}"
    "--set OPENCODE_DISABLE_AUTOUPDATE true"
  ] ++ lib.optional prev.stdenv.hostPlatform.isLinux
    "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ prev.wayland ]}";
in
{
  opencode = prev.stdenvNoCC.mkDerivation {
    pname = "opencode";
    inherit version;

    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@opencode/cli-${target.npmPlatform}/-/cli-${target.npmPlatform}-${version}.tgz";
      inherit (target) hash;
    };

    sourceRoot = "package";
    dontConfigure = true;
    dontBuild = true;
    # Keep the fetched bytes byte-for-byte: the interpreter/RPATH are set below
    # and fixup's shrink-rpath/strip would rewrite the executable (and, on
    # darwin, invalidate upstream's signature) — the bundle trailer sits at EOF.
    dontStrip = true;
    dontPatchELF = true;

    nativeBuildInputs = [ prev.patchelf prev.makeWrapper ];

    installPhase = ''
      runHook preInstall

      install -Dm755 bin/opencode $out/bin/opencode

      ${lib.optionalString prev.stdenv.hostPlatform.isLinux ''
        patchelf \
          --set-interpreter ${prev.glibc}/lib/ld-linux-${
            if prev.stdenv.hostPlatform.isAarch64 then "aarch64" else "x86-64"
          }.so.2 \
          --set-rpath ${lib.makeLibraryPath [ prev.glibc ]} \
          $out/bin/opencode
      ''}

      wrapProgram $out/bin/opencode ${lib.concatStringsSep " " wrapFlags}

      runHook postInstall
    '';

    doInstallCheck = prev.stdenvNoCC.buildPlatform.canExecute prev.stdenvNoCC.hostPlatform;
    installCheckPhase = ''
      runHook preInstallCheck
      export HOME="$TMPDIR"
      got="$($out/bin/opencode --version)"
      if [ "$got" != "opencode v${version}" ]; then
        echo "opencode --version: expected 'opencode v${version}', got '$got'" >&2
        exit 1
      fi
      runHook postInstallCheck
    '';

    meta = {
      description = "Open source AI coding agent";
      homepage = "https://opencode.ai";
      changelog = "https://github.com/anomalyco/opencode/releases";
      license = lib.licenses.mit;
      mainProgram = "opencode";
      platforms = builtins.attrNames targets;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };
}
