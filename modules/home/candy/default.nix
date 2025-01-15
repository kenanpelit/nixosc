# modules/home/candy/default.nix
{ pkgs, lib, ... }:
let
  candy-beauty = pkgs.stdenv.mkDerivation {
    pname = "candy-beauty-icon-theme";
    version = "2024-01-14";

    src = pkgs.fetchFromGitHub {
      owner = "arcolinux";
      repo = "a-candy-beauty-icon-theme-dev";
      rev = "6fbb3a69088c5816d00bcdee7b3ec5aee78ab1ce";
      sha256 = "1f1vvnby5ih917ply83r4nnc5d250hb3yigd521rqrsiyr60l52q";
    };

    nativeBuildInputs = [ pkgs.gtk3 ];  # gtk-update-icon-cache için gerekli

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/share/icons
      cp -r usr/share/icons/* $out/share/icons/

      # Icon cache'leri güncelle
      for theme in a-candy-beauty-icon-theme al-beautyline al-candy-icons; do
        theme_dir="$out/share/icons/$theme"
        if [ -d "$theme_dir" ]; then
          rm -f "$theme_dir/icon-theme.cache"
          gtk-update-icon-cache -f "$theme_dir"
        fi
      done
    '';

    meta = with lib; {
      description = "A collection of icon themes from ArcoLinux";
      homepage = "https://github.com/arcolinux/a-candy-beauty-icon-theme-dev";
      license = licenses.gpl3;
      platforms = platforms.all;
    };
  };
in {
  home.packages = [ candy-beauty ];
}
