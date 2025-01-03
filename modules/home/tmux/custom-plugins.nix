{ pkgs }:

let
  inherit (pkgs) fetchFromGitHub;
  inherit (pkgs.tmuxPlugins) mkTmuxPlugin;
in
{
  # Plugin: tmux-window-name
  tmux-window-name = mkTmuxPlugin {
    pluginName = "window-name";
    version = "unstable-2023";
    src = fetchFromGitHub {
      owner = "ofirgall";
      repo = "tmux-window-name";
      rev = "dc97a79ac35a9db67af558bb66b3a7ad41c924e7";
      hash = "sha256-o7ZzlXwzvbrZf/Uv0jHM+FiHjmBO0mI63pjeJwVJEhE=";
    };
  };

  # Plugin: tmux-ssh-status
  tmux-ssh-status = mkTmuxPlugin {
    pluginName = "ssh-status";
    version = "unstable-2023";
    src = fetchFromGitHub {
      owner = "kenanpelit";
      repo = "tmux-ssh-status";
      rev = "5d786c676f1bad6bdc1d9be5074859ba7e00427d";
      hash = "sha256-L+EqN/LYq+ROOh8w5oZ3/JXO5qxOPgrstLU6iuxQzko=";
    };
  };

  # Plugin: tmux-online-status
  tmux-online-status = mkTmuxPlugin {
    pluginName = "online-status";
    version = "unstable-2023";
    src = fetchFromGitHub {
      owner = "kenanpelit";
      repo = "tmux-online-status";
      rev = "82f4fbcaee7ece775f37cf7ed201f9d4beab76b8";
      hash = "sha256-vsR/OfcXK2YL4VmdVku3XxGbR5exgnbmlPVIQ2LnWBg=";
    };
  };
}
