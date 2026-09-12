# Named package groups shared across all hosts.
# A host enables/disables whole groups via `perry.systemGroups` (see
# common/common.nix). Headless servers: set perry.systemGroups = [ "dev" "containers" ];
{ pkgs }: {
  # --- safe on ANY host, including headless servers ---
  # (gitAndTools was removed in nixos-26.05 — its members now live at the
  # top level, so individual tools are added here as wanted.)
  dev = with pkgs; [
    git
  ];
  # (dockerTools is a helper attrset — pullImage/buildImage functions — not a
  # package; the client itself is just `docker`. Use dockerTools.pullImage or
  # dockerTools.buildImage for image tasks.)
  containers = with pkgs; [
    docker
  ];

  # --- desktop-only — omit on headless hosts ---
  browsers = with pkgs; [
    firefox
    brave
    google-chrome  # unfree; covered by nixpkgs.config.allowUnfree in common.nix
  ];
  graphics = with pkgs; [
    gimp
    darktable
    imagemagick
  ];
  media = with pkgs; [
    ffmpeg
    mpv
    vlc
  ];
  office = with pkgs; [
    libreoffice
  ];
}
