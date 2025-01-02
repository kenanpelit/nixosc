#!/bin/bash

# Kitty config dizini
KITTY_DIR="$HOME/.config/kitty"
FONTS_DIR="$KITTY_DIR/fonts"

# Fonts dizinini oluştur
mkdir -p "$FONTS_DIR"

# Mevcut JetBrains (font.conf) konfigürasyonu
cat >"$FONTS_DIR/jetbrains.conf" <<'EOL'
font_family JetBrainsMono Nerd Font
font_size 13.0

font_features JetBrainsMono-Regular +zero +ss01 +ss02 +ss03 +ss04 +ss05 +cv31
font_features JetBrainsMono-Bold +zero +ss01 +ss02 +ss03 +ss04 +ss05 +cv31
font_features JetBrainsMono-Italic +zero +ss01 +ss02 +ss03 +ss04 +ss05 +cv31
font_features JetBrainsMono-BoldItalic +zero +ss01 +ss02 +ss03 +ss04 +ss05 +cv31

adjust_line_height 0
adjust_column_width 0
disable_ligatures never

bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
bold_italic_font JetBrainsMono Nerd Font Bold Italic
EOL

# FiraCode config
cat >"$FONTS_DIR/firacode.conf" <<'EOL'
font_family FiraCode Nerd Font
font_size 13.0

font_features FiraCodeNF-Regular +zero +ss01 +ss02 +ss03 +ss04 +ss05 +cv31
font_features FiraCodeNF-Bold +zero +ss01 +ss02 +ss03 +ss04 +ss05 +cv31

adjust_line_height 0
adjust_column_width 0
disable_ligatures never

bold_font        FiraCode Nerd Font Bold
italic_font      FiraCode Nerd Font Italic
bold_italic_font FiraCode Nerd Font Bold Italic
EOL

# Hack config
cat >"$FONTS_DIR/hack.conf" <<'EOL'
font_family Hack Nerd Font
font_size 13.0

adjust_line_height 0
adjust_column_width 0
disable_ligatures never

bold_font        Hack Nerd Font Bold
italic_font      Hack Nerd Font Italic
bold_italic_font Hack Nerd Font Bold Italic
EOL

# Cascadia Code config
cat >"$FONTS_DIR/cascadia.conf" <<'EOL'
font_family CaskaydiaCove Nerd Font
font_size 13.0

font_features CaskaydiaCove-Regular +zero +ss01 +ss02 +ss03 +ss04 +ss05 +cv31
font_features CaskaydiaCove-Bold +zero +ss01 +ss02 +ss03 +ss04 +ss05 +cv31

adjust_line_height 0
adjust_column_width 0
disable_ligatures never

bold_font        CaskaydiaCove Nerd Font Bold
italic_font      CaskaydiaCove Nerd Font Italic
bold_italic_font CaskaydiaCove Nerd Font Bold Italic
EOL

# Iosevka config
cat >"$FONTS_DIR/iosevka.conf" <<'EOL'
font_family Iosevka Nerd Font
font_size 13.0

adjust_line_height 0
adjust_column_width 0
disable_ligatures never

bold_font        Iosevka Nerd Font Bold
italic_font      Iosevka Nerd Font Italic
bold_italic_font Iosevka Nerd Font Bold Italic
EOL

# Font test script
cat >"$FONTS_DIR/test-fonts.sh" <<'EOL'
#!/bin/bash

KITTY_DIR="$HOME/.config/kitty"
FONTS_DIR="$KITTY_DIR/fonts"
FONT_CONF="$KITTY_DIR/font.conf"
ORIGINAL_FONT_CONF="$KITTY_DIR/font.conf.bk"

# Mevcut font.conf'u yedekle
if [ -f "$FONT_CONF" ]; then
    cp "$FONT_CONF" "$ORIGINAL_FONT_CONF"
fi

test_font() {
    local font_conf="$1"
    echo "Testing font configuration: $font_conf"
    cp "$font_conf" "$FONT_CONF"
    kitty --config "$KITTY_DIR/kitty.conf" & 
    pid=$!
    echo "Press Enter to test next font (Ctrl+C to exit)..."
    read
    kill $pid
}

echo "Font Test Starting..."
echo "Each font will open in a new Kitty window."
echo "Press Enter to cycle through fonts."

for conf in "$FONTS_DIR"/*.conf; do
    if [ -f "$conf" ] && [[ "$conf" != *"test-fonts.sh"* ]]; then
        test_font "$conf"
    fi
done

# Test sonrası orijinal font.conf'u geri yükle
if [ -f "$ORIGINAL_FONT_CONF" ]; then
    cp "$ORIGINAL_FONT_CONF" "$FONT_CONF"
    rm "$ORIGINAL_FONT_CONF"
fi

echo "Font testing completed!"
echo "To use a specific font configuration permanently, copy the desired .conf file to font.conf"
echo "Example: cp $FONTS_DIR/firacode.conf $KITTY_DIR/font.conf"
EOL

# Test scriptini çalıştırılabilir yap
chmod +x "$FONTS_DIR/test-fonts.sh"

echo "Font konfigürasyonları oluşturuldu: $FONTS_DIR"
echo "Fontları test etmek için şunu çalıştırın: $FONTS_DIR/test-fonts.sh"
echo "Test sonrası beğendiğiniz font dosyasını font.conf'a kopyalayabilirsiniz."
echo "Örnek: cp $FONTS_DIR/firacode.conf $KITTY_DIR/font.conf"
