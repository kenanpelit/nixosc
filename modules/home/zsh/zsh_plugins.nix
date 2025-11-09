# modules/home/zsh/zsh_plugins.nix
# ==============================================================================
# ZSH Plugin Configuration - Updated with Correct Hashes
# Description: Plugin management for ZSH
# Note: Powerlevel10k removed, using Starship prompt instead
# ==============================================================================
{ pkgs, ... }:
{
  programs.zsh = {
    plugins = [
      # ========================================================================
      # Syntax Highlighting (FAST version - better than default)
      # ========================================================================
      {
        name = "fast-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zdharma-continuum";
          repo = "fast-syntax-highlighting";
          rev = "3d574ccf48804b10dca52625df13da5edae7f553";
          sha256 = "085132b1s114six9s4643ghgcmmn6allj2w1z1alymj0h8pm8a36";
        };
      }
      
      # ========================================================================
      # Auto Suggestions (History-based)
      # ========================================================================
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5";
          sha256 = "1885w3crr503h5n039kmg199sikb1vw1fvaidwr21sj9mn01fs9a";
        };
      }
      
      # ========================================================================
      # FZF Tab Completion
      # ========================================================================
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "fc6f0dcb2d5e41a4a685bfe9af2f2393dc39f689";
          sha256 = "1nvvcjkbndyv7jva2qnx0dbglgpy0512qzip4p6nad78hr7f83fn";
        };
      }
      
      # ========================================================================
      # Additional Completions
      # ========================================================================
      {
        name = "zsh-completions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-completions";
          rev = "5f24f3bc42c8a1ccbfa4260a3546590ae24fc843";
          sha256 = "00pmyckblzsfdi6g5pb6l0k5dmy788bsp910zrxpiqpr5mlibsyn";
        };
      }
      
      # ========================================================================
      # History Management (FIXED HASH)
      # ========================================================================
      {
        name = "zsh-hist";
        src = pkgs.fetchFromGitHub {
          owner = "marlonrichert";
          repo = "zsh-hist";
          rev = "0ef87bdb5847ae0df8536111f2b9888048e2e35c";
          sha256 = "PXHxPxFeoYXYMOC29YQKDdMnqTO0toyA7eJTSCV6PGE=";  # DÜZELTME
        };
      }
      
      # ========================================================================
      # Auto-pair Brackets/Quotes (RECOMMENDED)
      # ========================================================================
      {
        name = "zsh-autopair";
        src = pkgs.fetchFromGitHub {
          owner = "hlissner";
          repo = "zsh-autopair";
          rev = "396c38a7468458ba29011f2ad4112e4fd35f78e6";
          sha256 = "PXHxPxFeoYXYMOC29YQKDdMnqTO0toyA7eJTSCV6PGE=";
        };
      }
    ];
  };
}

