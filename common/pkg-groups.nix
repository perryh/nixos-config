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
    vim
    curl
    jq
  ];
  # --- safe on ANY host, including headless servers ---
  # (gitAndTools was removed in nixos-26.05 — its members now live at the
  # top level, so individual tools are added here as wanted.)
  dev = with pkgs; [
    git
    pnpm
  ];
  # Common network/diagnostic tools — safe on any host.
  # (26.05 removed `networkutils` and `bindutils`: ifconfig/netstat/route
  # live in `net-tools`, dig/nslookup are the `bind.dnsutils` output.)
  net = with pkgs; [
    whois
    net-tools
    iputils
    bind.dnsutils
    mtr
    netcat
    nmap
  ];
  # Language toolchains. Safe on any host, but best tracked via
  # perry.unstableGroups: the stable 26.05 pin lags (python3 3.13, rust 1.95)
  # while the unstable pin follows upstream.
  langs = with pkgs; [
    go_latest  # latest Go release (plain `go` lags one release behind)
    python3
    ruby
    rustc  # (top-level `rust` is the platform attrset, not a package)
    cargo
    nodejs_24  # latest Node LTS (nodejs_26 is current non-LTS until ~Oct 2026)
  ];
  # herdr (AI coding-agent multiplexer) and omp (terminal coding agent,
  # omp.sh) are only in nixpkgs-unstable, not the stable 26.05 pin — track
  # them via perry.unstableGroups = [ "ai" ]. Selecting this group from the
  # stable set errors on purpose.
  # dsh (DeepSeek Harness) is repo-local (pkgs/dsh, not in any nixpkgs) and
  # available from both sets via the pkgs/ overlay.
  ai = [
    (pkgs.herdr or (throw (
      "herdr is only in nixpkgs-unstable — add \"ai\" to perry.unstableGroups"
    )))
    (pkgs.omp or (throw (
      "omp is only in nixpkgs-unstable — add \"ai\" to perry.unstableGroups"
    )))
    pkgs.opencode
    pkgs.dsh
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
    digikam    # photo library manager; SD-card ingest + Google Photos export
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
  # GUI developer tools — desktop hosts only. Best tracked via
  # perry.unstableGroups: VS Code releases monthly and the stable 26.05
  # pin lags behind.
  dev-gui = with pkgs; [
    vscode-fhs  # VS Code in an FHS wrapper (system libs for extensions)
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
