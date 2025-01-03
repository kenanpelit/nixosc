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
      sha256 = "sha256-048j942jgplqvqx65ljfc278fn7qrhqx4bzmgzcvmg9kgjap7dm3";
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
      sha256 = "sha256-0jnfa3n8lfmmnkn0lgjfmkkcx5gwfy3fcc0z797f9ayqy8vjmq9g";
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
      sha256 = "sha256-062qwxi46j7mjkk7d0mijx3rn4aznx5md7arw45ncaqpywwpzi5y";
    };
  };
}
