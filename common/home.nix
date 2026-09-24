# Shared user/home config (home-manager) — identical on every host.
# Host-specific user tweaks belong in hosts/<name>.nix under
# home-manager.users.perryh = { ... }.
{ pkgs, unstablePkgs, ... }: {
  home.stateVersion = "26.05";

  home.packages = (with pkgs; [
    ripgrep
    fzf
    eza
  ]) ++ [
    # herdr (AI coding-agent multiplexer) — per-user alongside omp, from the
    # same nixpkgs-unstable pin (unstable-only, like omp's package). On
    # perry-eb the "ai" system group installs the identical store path too
    # (deduped, no double install); on the Mac this is the only install.
    unstablePkgs.herdr
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
      modelRoles.default = "ggpc/qwen3.8-27b:high";
      providers.webSearchOrder = [
        "zai" "perplexity" "gemini" "anthropic" "codex" "xai" "exa"
        "tinyfish" "jina" "kagi" "tavily" "firecrawl" "brave" "kimi"
        "parallel" "synthetic" "searxng" "startpage" "duckduckgo"
        "ecosia" "google" "mojeek" "public"
      ];
      providers.memoryModel = "online";
      providers.imageOrder = [ "xai" ];
      setupVersion = 2;
      theme.dark = "amethyst";
      symbolPreset = "unicode";
      display.showTokenUsage = true;
      display.showTurnTime = true;
      memory.backend = "mnemopi";
      autolearn.enabled = true;
      autolearn.autoContinue = true;
      readLineNumbers = true;
      read.renderMarkdown = true;
      bash.enabled = true;
      astGrep.enabled = true;
      generate_image.enabled = true;
      checkpoint.enabled = true;
      github.enabled = true;
      security.enabled = true;
      computer.enabled = true;
      commands.enableOpencodeUser = true;
      browser.headless = true;
      composer.tokenRate = true; # show streaming tok/s at the composer
      display.cacheMissMarker = true; # flag assistant turns that missed the prompt cache
    };
  };

  # Custom OMP models live in models.yml, separately from config.yml.
  home.file.".omp/agent/models.yml".source =
    (pkgs.formats.yaml { }).generate "omp-models.yml" {
      providers.ggpc = {
        baseUrl = "http://ggpc:8080/v1";
        api = "openai-completions";
        auth = "none";
        models = [
          {
            id = "qwen3.8-27b";
            name = "Qwen 3.8 27B (GGPC)";
            reasoning = true;
            input = [ "text" ];
            supportsTools = true;
            contextWindow = 262144;
            maxTokens = 16384;
            compat = {
              supportsToolChoice = true;
              supportsForcedToolChoice = false;
            };
          }
        ];
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
