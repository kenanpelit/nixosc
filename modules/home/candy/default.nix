# modules/home/candy/default.nix
# ==============================================================================
# Candy Beauty Icon Theme Configuration (Updated to specific commit)
# ==============================================================================
{ pkgs, lib, ... }:
let
  # =============================================================================
  # Theme Package Definition
  # =============================================================================
  candy-beauty = pkgs.stdenv.mkDerivation {
    pname = "candy-beauty-icon-theme";
    version = "2024-07-10-ce6be83";  # Updated version with commit hash
    
    src = pkgs.fetchFromGitHub {
      owner = "arcolinux";
      repo = "a-candy-beauty-icon-theme-dev";
      rev = "ce6be83e4cfdb64b9e0f34bcbb030449fa530c6b";  # Updated to your specified commit
      sha256 = "sha256-VDVAoH1IdkHxEFJkSsx7i5SpsYJWUgwfCgeF2iOkmDI=";
    };
    
    nativeBuildInputs = with pkgs; [ 
      gtk3  # gtk-update-icon-cache için gerekli
    ];
    
    dontBuild = true;
    
    # =============================================================================
    # Installation Configuration
    # =============================================================================
    installPhase = ''
      runHook preInstall
      
      mkdir -p $out/share/icons
      
      # Icon tema dosyalarını kopyala
      if [ -d "usr/share/icons" ]; then
        cp -r usr/share/icons/* $out/share/icons/
      else
        # Eğer farklı bir dizin yapısı varsa
        find . -name "*.png" -o -name "*.svg" -o -name "index.theme" | while read file; do
          # Tema dizinini bul ve kopyala
          echo "Processing: $file"
        done
        # Manuel kopyalama gerekirse buraya ekle
        cp -r ./* $out/share/icons/ 2>/dev/null || true
      fi
      
      # Icon cache'leri güncelle ve hataları yoksay
      for theme_dir in $out/share/icons/*/; do
        if [ -f "$theme_dir/index.theme" ]; then
          theme_name=$(basename "$theme_dir")
          echo "Updating icon cache for: $theme_name"
          rm -f "$theme_dir/icon-theme.cache"
          gtk-update-icon-cache -f -t "$theme_dir" 2>/dev/null || {
            echo "Warning: Could not update icon cache for $theme_name"
          }
        fi
      done
      
      runHook postInstall
    '';
    
    # =============================================================================
    # Post Installation Fixes
    # =============================================================================
    postInstall = ''
      # Tema dosyalarının doğru izinlerde olduğundan emin ol
      find $out/share/icons -type f -exec chmod 644 {} \;
      find $out/share/icons -type d -exec chmod 755 {} \;
      
      # Eksik index.theme dosyaları için basit bir tane oluştur
      for theme_dir in $out/share/icons/*/; do
        theme_name=$(basename "$theme_dir")
        if [ ! -f "$theme_dir/index.theme" ] && [ -d "$theme_dir" ]; then
          cat > "$theme_dir/index.theme" << EOF
[Icon Theme]
Name=$theme_name
Comment=Candy Beauty Icon Theme - $theme_name
Inherits=hicolor
Directories=16x16,22x22,24x24,32x32,48x48,64x64,96x96,128x128,256x256,scalable

EOF
          # Mevcut dizinleri tespit et ve ekle
          find "$theme_dir" -mindepth 1 -maxdepth 1 -type d | while read dir; do
            dir_name=$(basename "$dir")
            echo "[$dir_name]" >> "$theme_dir/index.theme"
            echo "Size=48" >> "$theme_dir/index.theme"
            echo "Context=Applications" >> "$theme_dir/index.theme"
            echo "Type=Fixed" >> "$theme_dir/index.theme"
            echo "" >> "$theme_dir/index.theme"
          done
        fi
      done
    '';
    
    # =============================================================================
    # Package Metadata
    # =============================================================================
    meta = with lib; {
      description = "A collection of beautiful icon themes from ArcoLinux";
      longDescription = ''
        Candy Beauty Icon Theme is a comprehensive collection of modern and 
        beautiful icon themes developed by the ArcoLinux team. This package
        includes multiple theme variants optimized for different desktop
        environments and use cases.
      '';
      homepage = "https://github.com/arcolinux/a-candy-beauty-icon-theme-dev";
      license = licenses.gpl3Plus;
      platforms = platforms.linux;
      maintainers = [ ];
    };
  };
in 
{
  # =============================================================================
  # Theme Installation and Configuration
  # =============================================================================
  home.packages = [ candy-beauty ];
  
  # =============================================================================
  # GTK Theme Configuration (Opsiyonel)
  # =============================================================================
  # Eğer bu icon theme'ini varsayılan yapmak istersen:
  # gtk = {
  #   enable = true;
  #   iconTheme = {
  #     name = "a-candy-beauty-icon-theme";  # Gerçek tema adını kontrol et
  #     package = candy-beauty;
  #   };
  # };
}

