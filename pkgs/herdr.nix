# herdr — terminal multiplexer for AI coding agents (https://herdr.dev)
# Not in nixpkgs; pinned to a GitHub release binary. To upgrade:
#   download the new binary, sha256sum it, convert to base64 SRI hash,
#   update version + url + hash below, then nix flake check / rebuild.
final: prev: {
  herdr = final.runCommand "herdr-0.9.0" {
    src = final.fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v0.9.0/herdr-linux-x86_64";
      hash = "sha256-T6GgEVjdgEPaktMbJweAsNzBBgMDjZthysTYGrY/tx8=";
    };
  } ''
    install -D $src $out/bin/herdr
    chmod 755 $out/bin/herdr
  '';
}
