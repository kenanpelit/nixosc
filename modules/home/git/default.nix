# modules/home/git/default.nix
# ==============================================================================
# Git Configuration - Complete with All Git Aliases
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
        syntax-theme = "Nord";
      };
    };
  };
  
  # =============================================================================
  # Additional Git Tools
  # =============================================================================
  home.packages = with pkgs; [ 
    gh              # GitHub CLI
    lazygit         # Terminal UI for Git
    onefetch        # Git repository summary
    #git-lfs        # Git Large File Storage
  ];
  
  # =============================================================================
  # Complete Git Aliases - All Git Commands Here
  # =============================================================================
  programs.zsh.shellAliases = {
    # ---------------------------------------------------------------------------
    # Core Git Commands
    # ---------------------------------------------------------------------------
    g = "git";
    gs = "git status -sb";           # Short status
    ga = "git add";
    gaa = "git add -A";              # Add all
    gc = "git commit -m";
    gca = "git commit -am";          # Add and commit
    gcm = "git commit -m";
    gcma = "git add -A && git commit -m";  # Add all and commit
    
    # ---------------------------------------------------------------------------
    # Branching & Navigation
    # ---------------------------------------------------------------------------
    gb = "git branch";
    gba = "git branch -a";           # All branches
    gco = "git checkout";
    gcb = "git checkout -b";         # Create and checkout branch
    gch = "git checkout";            # Alternative
    gchb = "git checkout -b";        # Alternative
    gm = "git merge";
    
    # ---------------------------------------------------------------------------
    # Remote Operations
    # ---------------------------------------------------------------------------
    gp = "git push";
    gpl = "git pull";
    gplo = "git pull origin";
    gps = "git push";
    gpso = "git push origin";
    gpst = "git push --follow-tags";
    gr = "git remote -v";
    
    # ---------------------------------------------------------------------------
    # Diff & Show
    # ---------------------------------------------------------------------------
    gd = "git diff";
    gds = "git diff --staged";
    gdt = "git diff-tree --no-commit-id --name-only -r";  # Show files in commit
    
    # ---------------------------------------------------------------------------
    # Stashing
    # ---------------------------------------------------------------------------
    gst = "git stash";
    gstp = "git stash pop";
    gstl = "git stash list";
    gsts = "git stash show";
    
    # ---------------------------------------------------------------------------
    # Log & History (Enhanced)
    # ---------------------------------------------------------------------------
    gl = "git log --oneline -10";
    glog = "git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative";
    glol = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'";
    glola = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all";
    glols = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat";
    
    # ---------------------------------------------------------------------------
    # Undo & Reset Operations
    # ---------------------------------------------------------------------------
    gundo = "git reset --soft HEAD~1";     # Undo last commit, keep changes
    greset = "git reset --hard HEAD";      # Hard reset to HEAD
    gclean = "git clean -fd";              # Clean untracked files
    
    # ---------------------------------------------------------------------------
    # Repository Operations
    # ---------------------------------------------------------------------------
    gcl = "git clone";
    gtag = "git tag -ma";
    ginit = "git init && git add . && git commit -m 'Initial commit'";
    
    # ---------------------------------------------------------------------------
    # Git Tools Integration
    # ---------------------------------------------------------------------------
    lg = "lazygit";                        # Lazygit TUI
    lzg = "lazygit";                       # Alternative
    gf = "onefetch --number-of-file-churns 0 --no-color-palette";  # Repository info
    ghc = "gh repo create";                # GitHub create repo
    ghv = "gh repo view --web";            # View repo in browser
    
    # ---------------------------------------------------------------------------
    # Advanced Git Operations
    # ---------------------------------------------------------------------------
    gignore = "git update-index --assume-unchanged";     # Ignore file changes
    gunignore = "git update-index --no-assume-unchanged"; # Unignore file changes
    gwip = "git add -A && git commit -m 'WIP' --no-verify";  # Work in progress commit
    gunwip = "git log -1 --pretty=%B | grep -q 'WIP' && git reset HEAD~1 || echo 'Last commit is not WIP'";  # Undo WIP
    
    # ---------------------------------------------------------------------------
    # Useful Git Shortcuts
    # ---------------------------------------------------------------------------
    gcount = "git shortlog -sn";           # Contributor stats
    gsize = "git count-objects -vH";       # Repository size
    gwho = "git shortlog -s --";           # Who contributed to file
    gwhen = "git log --follow --patch --"; # When file was changed
  };
}

