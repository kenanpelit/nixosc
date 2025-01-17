# modules/home/zsh/zsh_history.nix
{ config, lib, pkgs, ... }:

{
  home.activation = {
    appendZshHistory = lib.hm.dag.entryAfter ["writeBoundary"] ''
      HISTORY_FILE="${config.home.homeDirectory}/.config/zsh/history"
      EXAMPLE_HISTORY=${./history}

      # İzinleri ayarla
      $DRY_RUN_CMD chmod 644 "$HISTORY_FILE"
      $DRY_RUN_CMD chown ${config.home.username}:users "$HISTORY_FILE"

      # Örnek history içeriğini mevcut history'ye ekle
      # grep ile aynı komutları tekrar eklememek için kontrol ediyoruz
      while IFS= read -r line; do
        if ! grep -Fxq "$line" "$HISTORY_FILE" 2>/dev/null; then
          echo "$line" >> "$HISTORY_FILE"
        fi
      done < "$EXAMPLE_HISTORY"
    '';
  };
}
