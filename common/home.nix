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
    shellOptions = [ "histignoredups" ];
    initExtra = ''
      export EDITOR=nvim
    '';
  };

  programs.git = {
    enable = true;
    userName = "perryh";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
