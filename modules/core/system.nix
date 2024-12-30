{
 self,
 pkgs,
 lib,
 inputs,
 ...
}:
{
 # Temel nix sistem ayarları
 nix = {
   settings = {
     auto-optimise-store = true;
     experimental-features = [
       "nix-command"
       "flakes" 
     ];
     substituters = [ "https://nix-gaming.cachix.org" ];
     trusted-public-keys = [
       "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
     ];
   };
 };

 # NUR overlay'i ekle
 nixpkgs = {
   overlays = [ inputs.nur.overlays.default ];
 };

 # Temel sistem paketleri
 environment.systemPackages = with pkgs; [
   wget
   git
 ];

 # Saat dilimi ayarı
 time.timeZone = "Europe/Istanbul";

 # Dil ve yerelleştirme ayarları
 i18n.defaultLocale = "en_US.UTF-8";
 i18n.extraLocaleSettings = {
   LC_ADDRESS = "tr_TR.UTF-8";
   LC_IDENTIFICATION = "tr_TR.UTF-8";
   LC_MEASUREMENT = "tr_TR.UTF-8";
   LC_MONETARY = "tr_TR.UTF-8";
   LC_NAME = "tr_TR.UTF-8";
   LC_NUMERIC = "tr_TR.UTF-8";
   LC_PAPER = "tr_TR.UTF-8";
   LC_TELEPHONE = "tr_TR.UTF-8";
   LC_TIME = "tr_TR.UTF-8";
 };

 # X11 klavye ayarları
 services.xserver.xkb = {
   layout = "tr";
   variant = "f";
   options = "ctrl:nocaps";
 };

 # Konsol klavye ayarı
 console.keyMap = "trf";

 # Unfree paketlere izin ver
 nixpkgs.config.allowUnfree = true;

 # Sistem sürümü
 system.stateVersion = "24.11";
}
