# Apps that track nixpkgs-unstable instead of the stable nixpkgs pin, so they
# always get the newest upstream version. The OS itself stays on the stable
# branch — only these app packages are replaced via a nixpkgs overlay.
#
# Groups in common/pkg-groups.nix reference them by the same names, so no
# changes are needed there. To pin an app back to the stable version, remove
# its line from the overlay.
unstablePkgs: { ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      vesktop = unstablePkgs.vesktop;             # Discord client
      slack = unstablePkgs.slack;
      ghostty = unstablePkgs.ghostty;
      signal-desktop = unstablePkgs.signal-desktop;
    })
  ];
}
