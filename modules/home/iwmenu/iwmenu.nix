# modules/home/iwmenu/iwmenu.nix
{ config, lib, pkgs, ... }:
{
 home.packages = [ 
   (pkgs.rustPlatform.buildRustPackage {
     pname = "iwmenu";
     version = "0.1.1";
     src = pkgs.fetchFromGitHub {
       owner = "e-tho";
       repo = "iwmenu";
       rev = "7b639704affff2e5195dd664adb0011aa281098c";
       sha256 = "04yzi9ggh97qwn12a9lzp5dr7sda2bqkgpdp1gsbd2p2kba05wjy";
     };
     
     cargoHash = "sha256-HrV01gynTrZvB0Jc+yNsgMuloaWm9yz8AIZK3EJYX2I=";
     
     nativeBuildInputs = with pkgs; [
       pkg-config
     ];
     doCheck = true;
     CARGO_BUILD_INCREMENTAL = "false";
     RUST_BACKTRACE = "full";
     copyLibs = true;
     meta = with pkgs.lib; {
       description = "Menu-driven Wi-Fi management interface for Linux";
       homepage = "https://github.com/e-tho/iwmenu";
       license = licenses.gpl3;
       maintainers = [ "e-tho" ];
       platforms = platforms.linux;
       mainProgram = "iwmenu";
     };
   })
 ];
}

