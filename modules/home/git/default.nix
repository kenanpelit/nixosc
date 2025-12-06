# modules/home/git/default.nix
# ==============================================================================
# Git Configuration - Complete with All Oh-My-Zsh Git Plugin Aliases
# ==============================================================================
{ pkgs, lib, config, ... }:
let 
  cfg = config.my.user.git;
in
{
  options.my.user.git = {
    enable = lib.mkEnableOption "git configuration";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Git Program Configuration
    # =============================================================================
    programs.git = {
      enable = true;
      
      # ---------------------------------------------------------------------------
      # User Settings
      # ---------------------------------------------------------------------------
      settings = {
        user = {
          name = "kenanpelit";
          email = "kenanpelit@gmail.com";
        };
        
        # -------------------------------------------------------------------------
        # Basic Settings
        # -------------------------------------------------------------------------
        init.defaultBranch = "main";
        credential.helper = "store";
        merge.conflictstyle = "diff3";
        diff.colorMoved = "default";
        
        # -------------------------------------------------------------------------
        # Core Settings
        # -------------------------------------------------------------------------
        core = {
          editor = "vim";
          whitespace = "trailing-space,space-before-tab";
          pager = "delta";  # Use delta as the default pager
        };
        
        # -------------------------------------------------------------------------
        # Interactive Settings (for delta integration)
        # -------------------------------------------------------------------------
        interactive.diffFilter = "delta --color-only";
        
        # -------------------------------------------------------------------------
        # Rebase and Pull Settings
        # -------------------------------------------------------------------------
        rebase.autoStash = true;
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };
    
    # =============================================================================
    # Delta Configuration (Better Git Diff Viewer)
    # =============================================================================
    programs.delta = {
      enable = true;
      # Note: Git integration is handled manually via core.pager and interactive.diffFilter
      # to avoid home-manager deprecation warnings
      
      options = {
        line-numbers = true;
        side-by-side = true;
        diff-so-fancy = true;
        navigate = true;
        syntax-theme = "Nord";
      };
    };
    
    # =============================================================================
    # Complete Git Aliases - Oh-My-Zsh Git Plugin + Custom
    # =============================================================================
    programs.zsh.shellAliases = {
      
      # ---------------------------------------------------------------------------
      # Basic Git Commands
      # ---------------------------------------------------------------------------
      g = "git";
      grt = "cd \"$(git rev-parse --show-toplevel || echo .)\"";  # Go to repo root
      
      # ---------------------------------------------------------------------------
      # Add & Staging Operations
      # ---------------------------------------------------------------------------
      ga = "git add";
      gaa = "git add --all";
      gapa = "git add --patch";
      gau = "git add --update";
      gav = "git add --verbose";
      gap = "git apply";
      gapt = "git apply --3way";
      
      # ---------------------------------------------------------------------------
      # Branch Operations
      # ---------------------------------------------------------------------------
      gb = "git branch";
      gba = "git branch --all";
      gbd = "git branch --delete";
      gbD = "git branch --delete --force";
      gbm = "git branch --move";
      gbnm = "git branch --no-merged";
      gbr = "git branch --remote";
      ggsup = "git branch --set-upstream-to=origin/$(git branch --show-current)";
      gbg = "LANG=C git branch -vv | grep \": gone\\]\"";
      gbgd = "LANG=C git branch --no-color -vv | grep \": gone\\]\" | cut -c 3- | awk '{print $1}' | xargs git branch -d";
      gbgD = "LANG=C git branch --no-color -vv | grep \": gone\\]\" | cut -c 3- | awk '{print $1}' | xargs git branch -D";
      
      # ---------------------------------------------------------------------------
      # Checkout & Switch Operations
      # ---------------------------------------------------------------------------
      gco = "git checkout";
      gcor = "git checkout --recurse-submodules";
      gcb = "git checkout -b";
      gcB = "git checkout -B";
      gsw = "git switch";
      gswc = "git switch --create";
      
      # ---------------------------------------------------------------------------
      # Commit Operations
      # ---------------------------------------------------------------------------
      gc = "git commit --verbose";
      gca = "git commit --verbose --all";
      "gca!" = "git commit --verbose --all --amend";
      "gcan!" = "git commit --verbose --all --no-edit --amend";
      "gcans!" = "git commit --verbose --all --signoff --no-edit --amend";
      "gcann!" = "git commit --verbose --all --date=now --no-edit --amend";
      "gc!" = "git commit --verbose --amend";
      gcn = "git commit --verbose --no-edit";
      "gcn!" = "git commit --verbose --no-edit --amend";
      gcam = "git commit --all --message";
      gcas = "git commit --all --signoff";
      gcasm = "git commit --all --signoff --message";
      gcs = "git commit --gpg-sign";
      gcss = "git commit --gpg-sign --signoff";
      gcssm = "git commit --gpg-sign --signoff --message";
      gcmsg = "git commit --message";
      gcsm = "git commit --signoff --message";
      gcfu = "git commit --fixup";
      
      # ---------------------------------------------------------------------------
      # Cherry Pick Operations
      # ---------------------------------------------------------------------------
      gcp = "git cherry-pick";
      gcpa = "git cherry-pick --abort";
      gcpc = "git cherry-pick --continue";
      
      # ---------------------------------------------------------------------------
      # Clone Operations
      # ---------------------------------------------------------------------------
      gcl = "git clone --recurse-submodules";
      gclf = "git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules";
      
      # ---------------------------------------------------------------------------
      # Clean Operations
      # ---------------------------------------------------------------------------
      gclean = "git clean --interactive -d";
      
      # ---------------------------------------------------------------------------
      # Config Operations
      # ---------------------------------------------------------------------------
      gcf = "git config --list";
      
      # ---------------------------------------------------------------------------
      # Diff Operations
      # ---------------------------------------------------------------------------
      gd = "git diff";
      gdca = "git diff --cached";
      gdcw = "git diff --cached --word-diff";
      gds = "git diff --staged";
      gdw = "git diff --word-diff";
      gdup = "git diff @{upstream}";
      gdt = "git diff-tree --no-commit-id --name-only -r";
      
      # ---------------------------------------------------------------------------
      # Fetch Operations
      # ---------------------------------------------------------------------------
      gf = "git fetch";
      gfa = "git fetch --all --tags --prune";
      gfo = "git fetch origin";
      
      # ---------------------------------------------------------------------------
      # GUI Operations
      # ---------------------------------------------------------------------------
      gg = "git gui citool";
      gga = "git gui citool --amend";
      
      # ---------------------------------------------------------------------------
      # Help Operations
      # ---------------------------------------------------------------------------
      ghh = "git help";
      
      # ---------------------------------------------------------------------------
      # Log Operations (Enhanced)
      # ---------------------------------------------------------------------------
      glog = "git log --oneline --decorate --graph";
      gloga = "git log --oneline --decorate --graph --all";
      glo = "git log --oneline --decorate";
      glgg = "git log --graph";
      glgga = "git log --graph --decorate --all";
      glgm = "git log --graph --max-count=10";
      glods = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset\" --date=short";
      glod = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset\"";
      glola = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\" --all";
      glols = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\" --stat";
      glol = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\"";
      glg = "git log --stat";
      glgp = "git log --stat --patch";
      
      # ---------------------------------------------------------------------------
      # Special Log Operations
      # ---------------------------------------------------------------------------
      gdct = "git describe --tags $(git rev-list --tags --max-count=1)";
      gdg = "git log --graph --decorate --oneline $(git rev-list -g --all)";  # Reflog graph
      
      # ---------------------------------------------------------------------------
      # List Files Operations
      # ---------------------------------------------------------------------------
      gignored = "git ls-files -v | grep \"^[[:lower:]]\"";
      gfg = "git ls-files | grep";
      
      # ---------------------------------------------------------------------------
      # Merge Operations
      # ---------------------------------------------------------------------------
      gm = "git merge";
      gma = "git merge --abort";
      gmc = "git merge --continue";
      gms = "git merge --squash";
      gmff = "git merge --ff-only";
      gmtl = "git mergetool --no-prompt";
      gmtlvim = "git mergetool --no-prompt --tool=vimdiff";
      
      # ---------------------------------------------------------------------------
      # Pull Operations
      # ---------------------------------------------------------------------------
      gl = "git pull";
      gpr = "git pull --rebase";
      gprv = "git pull --rebase -v";
      gpra = "git pull --rebase --autostash";
      gprav = "git pull --rebase --autostash -v";
      ggpull = "git pull origin \"$(git branch --show-current)\"";
      
      # ---------------------------------------------------------------------------
      # Push Operations
      # ---------------------------------------------------------------------------
      gp = "git push";
      gpd = "git push --dry-run";
      "gpf!" = "git push --force";
      gpf = "git push --force-with-lease";
      gpsup = "git push --set-upstream origin $(git branch --show-current)";
      gpsupf = "git push --set-upstream origin $(git branch --show-current) --force-with-lease";
      gpv = "git push --verbose";
      gpoat = "git push origin --all && git push origin --tags";
      gpod = "git push origin --delete";
      ggpush = "git push origin \"$(git branch --show-current)\"";
      gpu = "git push upstream";
      
      # ---------------------------------------------------------------------------
      # Rebase Operations
      # ---------------------------------------------------------------------------
      grb = "git rebase";
      grba = "git rebase --abort";
      grbc = "git rebase --continue";
      grbi = "git rebase --interactive";
      grbo = "git rebase --onto";
      grbs = "git rebase --skip";
      
      # ---------------------------------------------------------------------------
      # Reflog Operations
      # ---------------------------------------------------------------------------
      grf = "git reflog";
      
      # ---------------------------------------------------------------------------
      # Remote Operations
      # ---------------------------------------------------------------------------
      gr = "git remote";
      grv = "git remote --verbose";
      gra = "git remote add";
      grrm = "git remote remove";
      grmv = "git remote rename";
      grset = "git remote set-url";
      grup = "git remote update";
      
      # ---------------------------------------------------------------------------
      # Reset Operations
      # ---------------------------------------------------------------------------
      grh = "git reset";
      gru = "git reset --";
      grhh = "git reset --hard";
      grhk = "git reset --keep";
      grhs = "git reset --soft";
      gpristine = "git reset --hard && git clean --force -dfx";
      gwipe = "git reset --hard && git clean --force -df";
      groh = "git reset origin/$(git branch --show-current) --hard";
      
      # ---------------------------------------------------------------------------
      # Restore Operations
      # ---------------------------------------------------------------------------
      grs = "git restore";
      grss = "git restore --source";
      grst = "git restore --staged";
      
      # ---------------------------------------------------------------------------
      # Revert Operations
      # ---------------------------------------------------------------------------
      grev = "git revert";
      greva = "git revert --abort";
      grevc = "git revert --continue";
      
      # ---------------------------------------------------------------------------
      # Remove Operations
      # ---------------------------------------------------------------------------
      grm = "git rm";
      grmc = "git rm --cached";
      
      # ---------------------------------------------------------------------------
      # Show Operations
      # ---------------------------------------------------------------------------
      gsh = "git show";
      gsps = "git show --pretty=short --show-signature";
      
      # ---------------------------------------------------------------------------
      # Stash Operations
      # ---------------------------------------------------------------------------
      gsta = "git stash push";
      gstall = "git stash --all";
      gstaa = "git stash apply";
      gstc = "git stash clear";
      gstd = "git stash drop";
      gstl = "git stash list";
      gstp = "git stash pop";
      gsts = "git stash show --patch";
      gstu = "git stash push --include-untracked";
      
      # ---------------------------------------------------------------------------
      # Status Operations
      # ---------------------------------------------------------------------------
      gst = "git status";
      gss = "git status --short";
      gsb = "git status --short --branch";
      
      # ---------------------------------------------------------------------------
      # Submodule Operations
      # ---------------------------------------------------------------------------
      gsi = "git submodule init";
      gsu = "git submodule update";
      
      # ---------------------------------------------------------------------------
      # SVN Operations
      # ---------------------------------------------------------------------------
      gsd = "git svn dcommit";
      gsr = "git svn rebase";
      
      # ---------------------------------------------------------------------------
      # Tag Operations
      # ---------------------------------------------------------------------------
      gta = "git tag --annotate";
      gts = "git tag --sign";
      gtv = "git tag | sort -V";
      
      # ---------------------------------------------------------------------------
      # Update Index Operations
      # ---------------------------------------------------------------------------
      gignore = "git update-index --assume-unchanged";
      gunignore = "git update-index --no-assume-unchanged";
      
      # ---------------------------------------------------------------------------
      # What Changed Operations
      # ---------------------------------------------------------------------------
      gwch = "git whatchanged -p --abbrev-commit --pretty=medium";
      
      # ---------------------------------------------------------------------------
      # Worktree Operations
      # ---------------------------------------------------------------------------
      gwt = "git worktree";
      gwta = "git worktree add";
      gwtls = "git worktree list";
      gwtmv = "git worktree move";
      gwtrm = "git worktree remove";
      
      # ---------------------------------------------------------------------------
      # Work in Progress Operations
      # ---------------------------------------------------------------------------
      gwip = "git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message \"--wip-- [skip ci]\"";
      gunwip = "git rev-list --max-count=1 --format=\"%s\" HEAD | grep -q \"\\--wip--\" && git reset HEAD~1";
      
      # ---------------------------------------------------------------------------
      # Bisect Operations
      # ---------------------------------------------------------------------------
      gbs = "git bisect";
      gbsb = "git bisect bad";
      gbsg = "git bisect good";
      gbsn = "git bisect new";
      gbso = "git bisect old";
      gbsr = "git bisect reset";
      gbss = "git bisect start";
      
      # ---------------------------------------------------------------------------
      # Blame Operations
      # ---------------------------------------------------------------------------
      gbl = "git blame -w";
      
      # ---------------------------------------------------------------------------
      # Apply Patch Operations
      # ---------------------------------------------------------------------------
      gam = "git am";
      gama = "git am --abort";
      gamc = "git am --continue";
      gamscp = "git am --show-current-patch";
      gams = "git am --skip";
      
      # ---------------------------------------------------------------------------
      # Shortlog Operations
      # ---------------------------------------------------------------------------
      gcount = "git shortlog --summary --numbered";
      
      # ---------------------------------------------------------------------------
      # Gitk Operations
      # ---------------------------------------------------------------------------
      gk = "gitk --all --branches";
      gke = "gitk --all $(git log --walk-reflogs --pretty=%h)";
      
      # ---------------------------------------------------------------------------
      # Custom Git Tools Integration
      # ---------------------------------------------------------------------------
      lg = "lazygit";                        # Lazygit TUI
      lzg = "lazygit";                       # Alternative
      ginfo = "onefetch --number-of-file-churns 0 --no-color-palette";  # Repository info
      ghc = "gh repo create";                # GitHub create repo
      ghv = "gh repo view --web";            # View repo in browser
      
      # ---------------------------------------------------------------------------
      # Useful Custom Shortcuts
      # ---------------------------------------------------------------------------
      ginit = "git init && git add . && git commit -m 'Initial commit'";
      gsize = "git count-objects -vH";       # Repository size
      gwho = "git shortlog -s --";           # Who contributed to file
      gwhen = "git log --follow --patch --"; # When file was changed
    };
  };
}
