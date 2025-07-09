# modules/home/git/default.nix
# ==============================================================================
# Git Configuration
# ==============================================================================
{ pkgs, ... }:
{
  # =============================================================================
  # Git Program Configuration
  # =============================================================================
  programs.git = {
    enable = true;
    userName = "kenanpelit";
    userEmail = "kenanpelit@gmail.com";
    
    # ---------------------------------------------------------------------------
    # Basic Settings
    # ---------------------------------------------------------------------------
    extraConfig = {
      init.defaultBranch = "main";
      credential.helper = "store";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      core = {
        editor = "vim";
        whitespace = "trailing-space,space-before-tab";
      };
      rebase.autoStash = true;
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
    # ---------------------------------------------------------------------------
    # Delta Configuration (Git Diff Tool)
    # ---------------------------------------------------------------------------
    delta = {
      enable = true;
      options = {
        line-numbers = true;
        side-by-side = true;
        diff-so-fancy = true;
        navigate = true;
        syntax-theme = "Nord";  # Güzel bir tema
      };
    };
  };
  # =============================================================================
  # Additional Git Tools
  # =============================================================================
  home.packages = with pkgs; [ 
    gh              # GitHub CLI
    #git-lfs         # Git Large File Storage
    #lazygit         # Terminal UI for Git
    onefetch        # Git repository summary
  ];

  # =============================================================================
  # Shell Aliases Configuration
  # =============================================================================
  programs.zsh.shellAliases = {
    # ---------------------------------------------------------------------------
    # Basic Git Commands
    # ---------------------------------------------------------------------------
    g = "lazygit";
    gf = "onefetch --number-of-file-churns 0 --no-color-palette";
    ga = "git add";
    gaa = "git add --all";
    gs = "git status";
    gb = "git branch";
    gm = "git merge";
    gd = "git diff";

    # ---------------------------------------------------------------------------
    # Pull and Push Commands
    # ---------------------------------------------------------------------------
    gpl = "git pull";
    gplo = "git pull origin";
    gps = "git push";
    gpso = "git push origin";
    gpst = "git push --follow-tags";

    # ---------------------------------------------------------------------------
    # Repository Management
    # ---------------------------------------------------------------------------
    gcl = "git clone";
    gc = "git commit";
    gcm = "git commit -m";
    gcma = "git add --all && git commit -m";
    gtag = "git tag -ma";
    gch = "git checkout";
    gchb = "git checkout -b";

    # ---------------------------------------------------------------------------
    # Log and History Commands
    # ---------------------------------------------------------------------------
    glog = "git log --oneline --decorate --graph";
    glol = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'";
    glola = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all";
    glols = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat";
  };
}
