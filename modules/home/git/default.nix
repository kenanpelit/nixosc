# modules/home/git/default.nix
# ==============================================================================
# Git Configuration
# ==============================================================================
{ pkgs, config, lib, ... }:
let
 # Git kimlik bilgilerini sops'tan oku
 gitConfig = {
   userName = config.sops.secrets.git_user_name.path;
   userEmail = config.sops.secrets.git_user_email.path;
 };
in
{
 imports = [ ../sops ];

 # =============================================================================
 # Git Program Configuration
 # =============================================================================
 programs.git = {
   enable = true;

   userName = "${lib.fileContents gitConfig.userName}";
   userEmail = "${lib.fileContents gitConfig.userEmail}";
 
   # ---------------------------------------------------------------------------
   # Basic Settings
   # ---------------------------------------------------------------------------
   extraConfig = {
     init.defaultBranch = "main";
     credential.helper = "store"; # Kimlik bilgilerini saklamak için
     merge.conflictstyle = "diff3";
     diff.colorMoved = "default";
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
     };
   };
 };
 # =============================================================================
 # Additional Git Tools
 # =============================================================================
 home.packages = [ pkgs.gh ]; # GitHub CLI desteği
 # home.packages = [ pkgs.gh pkgs.git-lfs ]; # Gerekirse Git-LFS desteği
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

