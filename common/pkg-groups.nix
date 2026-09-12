# Named package groups shared across all hosts.
# A host enables/disables whole groups via `perry.systemGroups` (see
# common/common.nix). Headless servers: set perry.systemGroups = [ "dev" "containers" ];
{ pkgs }: {
  # --- safe on ANY host, including headless servers ---
  # gitAndTools = git + a curated bundle of git-adjacent tooling
  dev = with pkgs; [
    gitAndTools
  ];
  containers = with pkgs; [
    dockerTools
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
