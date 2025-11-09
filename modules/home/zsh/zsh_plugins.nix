# modules/home/zsh/zsh_plugins.nix
# ==============================================================================
# ZSH Plugin Configuration - Updated 2025-07-29
# Description: Plugin management and configuration for ZSH with latest versions
# Note: Powerlevel10k removed, using Starship prompt instead
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
          rev = "3d574ccf48804b10dca52625df13da5edae7f553";
          sha256 = "085132b1s114six9s4643ghgcmmn6allj2w1z1alymj0h8pm8a36";
        };
      }
      #{
      #  name = "zsh-you-should-use";
      #  src = pkgs.fetchFromGitHub {
      #    owner = "MichaelAquilina";
      #    repo = "zsh-you-should-use";
      #    rev = "78617df02e09fcc06f41a91d934b7048947fc62d";
      #    sha256 = "0acrqvzgyc1q86709mfkxdnyp7d2gxy32cacnrpndfwaqglq8vkl";
      #  };
      #}
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5";
          sha256 = "1885w3crr503h5n039kmg199sikb1vw1fvaidwr21sj9mn01fs9a";
        };
      }
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "fc6f0dcb2d5e41a4a685bfe9af2f2393dc39f689";
          sha256 = "1nvvcjkbndyv7jva2qnx0dbglgpy0512qzip4p6nad78hr7f83fn";
        };
      }
      # Powerlevel10k REMOVED - Using Starship instead
      #{
      #  name = "powerlevel10k";
      #  src = pkgs.fetchFromGitHub {
      #    owner = "romkatv";
      #    repo = "powerlevel10k";
      #    rev = "36f3045d69d1ba402db09d09eb12b42eebe0fa3b";
      #    sha256 = "1xjayg0qnm3pzi6ixydhql4w0l99h4wdfjgsi4b6ak50gwd744h5";
      #  };
      #  file = "powerlevel10k.zsh-theme";
      #}
      {
        name = "zsh-completions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-completions";
          rev = "5f24f3bc42c8a1ccbfa4260a3546590ae24fc843";
          sha256 = "00pmyckblzsfdi6g5pb6l0k5dmy788bsp910zrxpiqpr5mlibsyn";
        };
      }
      {
        name = "zsh-hist";
        src = pkgs.fetchFromGitHub {
          owner = "marlonrichert";
          repo = "zsh-hist";
          rev = "0ef87bdb5847ae0df8536111f2b9888048e2e35c";
          sha256 = "04bwkbc1sm8486vi9mmn3f42d1ka4igfydqcddczznj9jhkka3p8";
        };
      }
    ];
  };
}

