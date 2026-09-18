# Shared user/home config (home-manager) — identical on every host.
# Host-specific user tweaks belong in hosts/<name>.nix under
# home-manager.users.perryh = { ... }.
{ pkgs, unstablePkgs, ... }: {
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    ripgrep
    fzf
    eza
  ];
  # OMP coding agent (omp.sh). Moved here from the system "ai" group — the
  # package tracks the same nixpkgs-unstable pin it always did; the upstream
  # home-manager module owns the config. On every switch the declared
  # settings are installed to ~/.omp/agent/config.yml as a writable copy
  # (omp locks + rewrites the file at runtime), so runtime changes made
  # inside omp (/settings) are overwritten by these values next switch.
  # Migrated verbatim from the live config.yml on 2026-09-18.
  programs.omp = {
    enable = true;
    package = unstablePkgs.omp;
    settings = {
      setupVersion = 2;
      providers.webSearchOrder = [
        "xai" "perplexity" "gemini" "anthropic" "codex" "zai" "exa"
        "tinyfish" "jina" "kagi" "tavily" "firecrawl" "brave" "kimi"
        "parallel" "synthetic" "searxng" "startpage" "duckduckgo"
        "ecosia" "google" "mojeek" "public"
      ];
      modelRoles.default = "zai/glm-5.3-flash";
    };
  };

  programs.zsh = {
    enable = true;
    setOptions = [ "histignoredups" ];
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "sudo" "z" "extract" ];
    };
    initContent = ''
      export EDITOR=nvim
    '';
  };

  programs.git = {
    enable = true;
    # home-manager manages ~/.config/git/config (a symlink into the store),
    # so `git config --global` can't write it — declare identity here instead.
    # Shared, so every machine commits with the same identity.
    settings = {
      user.name = "Perry Huang";
      user.email = "perry.huang@gmail.com";
      init.defaultBranch = "main";
    };
  };
}
