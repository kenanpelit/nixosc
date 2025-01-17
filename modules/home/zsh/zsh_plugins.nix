# modules/home/zsh/zsh_plugins.nix
# ==============================================================================
# ZSH Plugin Configuration
# Description: Plugin management and configuration for ZSH
# ==============================================================================
{ pkgs, ... }:
{
  programs.zsh = {
    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zdharma-continuum";
          repo = "fast-syntax-highlighting";
          rev = "cf318e06a9b7c9f2219d78f41b46fa6e06011fd9";
          sha256 = "1bmrb724vphw7y2gwn63rfssz3i8lp75ndjvlk5ns1g35ijzsma5";
        };
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "0e810e5afa27acbd074398eefbe28d13005dbc15";
          sha256 = "0y866dsm8l164afbyd9cafbl97yf9viqwms9bbn0799nwgsb15pk";
        };
      }
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "6aced3f35def61c5edf9d790e945e8bb4fe7b305";
          sha256 = "1brljd9744wg8p9v3q39kdys33jb03d27pd0apbg1cz0a2r1wqqi";
        };
      }
      {
        name = "powerlevel10k";
        src = pkgs.fetchFromGitHub {
          owner = "romkatv";
          repo = "powerlevel10k";
          rev = "3e2053a9341fe4cf5ab69909d3f39d53b1dfe772";
          sha256 = "1gvbgw38wa0z1jvs3xqr5108aqsaajlw9xxha9lxyhb04rmsxmga";
        };
        file = "powerlevel10k.zsh-theme";
      }
      {
        name = "zsh-completions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-completions";
          rev = "a7f01622f7bc6941d1c6297be6995fe1bbc9d4de";
          sha256 = "035hwnv1qik35lmy3wy8821jf6y3qvc0hqd18ks5a7nqq6l5ffcl";
        };
      }
    ];
  };
}

