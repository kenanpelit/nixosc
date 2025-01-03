{ pkgs, lib }:

let
  inherit (pkgs) fetchFromGitHub;
  inherit (pkgs.tmuxPlugins) mkTmuxPlugin;
in
{
  tmux-window-name = mkTmuxPlugin {
    pluginName = "window-name";
    version = "unstable-2023";
    src = fetchFromGitHub {
      owner = "ofirgall";
      repo = "tmux-window-name";
      rev = "dc97a79ac35a9db67af558bb66b3a7ad41c924e7";
      hash = "sha256-o7ZzlXwzvbrZf/Uv0jHM+FiHjmBO0mI63pjeJwVJEhE=";
    };
    meta = with lib; {
      homepage = "https://github.com/ofirgall/tmux-window-name";
      description = "Automatically updates the tmux window name.";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  };

  tmux-ssh-status = mkTmuxPlugin {
    pluginName = "ssh-status";
    version = "unstable-2023";
    src = fetchFromGitHub {
      owner = "kenanpelit";
      repo = "tmux-ssh-status";
      rev = "5d786c676f1bad6bdc1d9be5074859ba7e00427d";
      hash = "sha256-L+EqN/LYq+ROOh8w5oZ3/JXO5qxOPgrstLU6iuxQzko=";
    };
    meta = with lib; {
      homepage = "https://github.com/kenanpelit/tmux-ssh-status";
      description = "Displays SSH connection status in the tmux status bar.";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  };

  tmux-online-status = mkTmuxPlugin {
    pluginName = "online-status";
    version = "unstable-2023";
    src = fetchFromGitHub {
      owner = "kenanpelit";
      repo = "tmux-online-status";
      rev = "82f4fbcaee7ece775f37cf7ed201f9d4beab76b8";
      hash = "sha256-vsR/OfcXK2YL4VmdVku3XxGbR5exgnbmlPVIQ2LnWBg=";
    };
    meta = with lib; {
      homepage = "https://github.com/kenanpelit/tmux-online-status";
      description = "Displays online/offline status in the tmux status bar.";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  };

  tmux-tokyo-night = mkTmuxPlugin {
    pluginName = "tokyo-night";
    rtpFilePath = "tokyo-night.tmux";
    version = "1.0.0";
    src = fetchFromGitHub {
      owner = "kenanpelit";
      repo = "tmux-tokyo-night";
      rev = "5ce373040f893c3a0d1cb93dc1e8b2a25c94d3da";
      hash = "sha256-9nDgiJptXIP+Hn9UY+QFMgoghw4HfTJ5TZq0f9KVOFg=";
    };
    meta = with lib; {
      homepage = "https://github.com/kenanpelit/tmux-tokyo-night";
      description = "A clean, dark Tmux theme.";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  };
}
