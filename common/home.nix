# Shared user/home config (home-manager) — identical on every host.
# Host-specific user tweaks belong in hosts/<name>.nix under
# home-manager.users.perryh = { ... }.
{ pkgs, ... }: {
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    ripgrep
    fzf
    eza
  ];

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
