# modules/home/candy/default.nix
# ==============================================================================
# Candy Icons Theme Configuration
# ==============================================================================
{ pkgs, lib, ... }:

{
  # =============================================================================
  # Theme Installation
  # =============================================================================
  # candy-icons paketi nixpkgs'de resmi olarak mevcut
  home.packages = [ pkgs.candy-icons ];
  
  # =============================================================================
  # GTK Icon Theme Configuration
  # =============================================================================
  gtk = {
    iconTheme = {
      name = "candy-icons";
      package = pkgs.candy-icons;
    };
  };
  
  # =============================================================================
  # Additional Configuration
  # =============================================================================
  # candy-icons paketi aşağıdaki varyantları içerir:
  # - candy-icons (ana tema)
  # 
  # Paket hakkında bilgi:
  # - Nixpkgs'de resmi paket olarak mevcut
  # - SVG tabanlı modern icon seti
  # - Hicolor temasından türetilmiş
  # - Otomatik olarak icon cache güncellenir
  
  # =============================================================================
  # Package Metadata (Bilgi Amaçlı)
  # =============================================================================
  # candy-icons paketi şunları içerir:
  # - Modern ve minimalist tasarım
  # - Geniş uygulama desteği
  # - Yüksek çözünürlük desteği
  # - Düzenli güncellemeler
}

