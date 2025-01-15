# modules/home/sops/default.nix
{ username, inputs, ... }:
{
 imports = [
   inputs.sops-nix.homeManagerModules.sops
 ];
 
 sops = {
   defaultSopsFile = ./../../../secrets/home-secrets.enc.yaml;
   age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
   validateSopsFiles = false;  # Bunu ekledik 

   secrets = {
     "github_token" = {
       path = "/home/${username}/.config/github/token";
     };
     
     "nix_conf" = {
       path = "/home/${username}/.config/nix/nix.conf";
       mode = "0600";
     };
     
     "tmux_backup_archive" = {
       path = "/home/${username}/.backup/tmux.tar.gz";
       mode = "0600";
       format = "binary";  # Binary format için gerekli
       sopsFile = ./../../../assets/tmux.enc.tar.gz;
     };
     "mpv_backup_archive" = {
       path = "/home/${username}/.backup/mpv.tar.gz";
       mode = "0600";
       format = "binary";
       sopsFile = ./../../../assets/mpv.enc.tar.gz;
#     };
#     "dot_backup_archive" = {
#       path = "/home/${username}/.backup/dot.tar.gz";
#       mode = "0600";
#       format = "binary";
#       #sopsFile = ./../../../assets/dot.enc.tar.gz;
#       # Projedeki assets yerine direkt home'daki .nixosc/assets'i kullanalım
#       sopsFile = "/home/${username}/.nixosc/assets/dot.enc.tar.gz";
     };
   };
 };
}
