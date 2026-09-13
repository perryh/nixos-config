# Named package groups shared across all hosts.
# A host enables/disables whole groups via `perry.systemGroups` (see
# common/common.nix). Headless servers: set perry.systemGroups =
# [ "core" "dev" "containers" ];
{ pkgs }: {
  # Base set, safe on ANY host. Every host needs these — they are part of
  # the "all groups" default, so desktops pick them up automatically.
  core = with pkgs; [
    gh
    neovim
    curl
    jq
  ];
  # --- safe on ANY host, including headless servers ---
  # (gitAndTools was removed in nixos-26.05 — its members now live at the
  # top level, so individual tools are added here as wanted.)
  dev = with pkgs; [
    git
  ];
  # herdr (AI coding-agent multiplexer) is only in nixpkgs-unstable, not the
  # stable 26.05 pin — track it via perry.unstableGroups = [ "ai" ].
  # Selecting this group from the stable set errors on purpose.
  ai = [
    (pkgs.herdr or (throw (
      "herdr is only in nixpkgs-unstable — add \"ai\" to perry.unstableGroups"
    )))
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
  terminals = with pkgs; [
    ghostty  # GPU-accelerated terminal (needs a desktop session)
  ];
  chat = with pkgs; [
    vesktop  # Discord desktop client (Vencord preinstalled)
    signal-desktop
    slack
  ];
}
