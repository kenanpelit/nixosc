# modules/home/ai/gemini-cli.nix
{ lib, stdenv, makeWrapper, nodejs }:
stdenv.mkDerivation rec {
  pname = "gemini-cli";
  version = "latest";
  
  src = builtins.toFile "dummy" "";
  
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nodejs ];
  
  dontUnpack = true;
  dontBuild = true;
  
  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin
    
    # Gemini CLI wrapper - stable version
    cat > $out/bin/ai-gemini << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
# HOME değişkenini ayarla
if [ -z "$HOME" ]; then
    export HOME=/tmp
fi
# NPM ayarları - local kullanıcı dizinleri ve uyarıları kapat
export NPM_CONFIG_CACHE="$HOME/.cache/npm"
export NPM_CONFIG_PREFIX="$HOME/.local"
export NPM_CONFIG_UPDATE_NOTIFIER=false
export NO_UPDATE_NOTIFIER=1
# Dizinleri oluştur
mkdir -p "$HOME/.cache/npm" "$HOME/.local/bin" "$HOME/.local/lib"
# Dinamik olarak nodejs path'ini bul
find_node() {
    # Önce PATH'teki node'u dene
    if command -v node >/dev/null 2>&1; then
        NODE_BIN=$(dirname $(command -v node))
        return 0
    fi
    
    # Nix profile'larda node ara
    for profile_path in /etc/profiles/per-user/*/bin /nix/var/nix/profiles/*/bin ~/.nix-profile/bin; do
        if [ -f "$profile_path/node" ]; then
            NODE_BIN="$profile_path"
            return 0
        fi
    done
    
    # Nix store'da en güncel nodejs'i bul
    local latest_node=$(find /nix/store -maxdepth 1 -name "*nodejs*" -type d 2>/dev/null | \
                       grep -E "nodejs-[0-9]+\\.[0-9]+" | \
                       sort -V | tail -1)
    
    if [ -n "$latest_node" ] && [ -f "$latest_node/bin/node" ]; then
        NODE_BIN="$latest_node/bin"
        return 0
    fi
    
    # Son çare: nix shell ile çalıştır
    echo "Node.js bulunamadı, nix shell kullanılıyor..." >&2
    exec nix shell nixpkgs#nodejs_24 -c "$0" "$@"
}
# Node'u bul ve PATH'e ekle
find_node
export PATH="$NODE_BIN:$HOME/.local/bin:$PATH"
# npx ile @google/gemini-cli çalıştır (resmi Google Gemini CLI)
exec "$NODE_BIN/npx" --yes @google/gemini-cli "$@"
EOF
    
    chmod +x $out/bin/ai-gemini

    # Provide a plain `gemini` binary so tools like Every Code
    # (code) can discover the CLI via `gemini --version`.
    ln -s $out/bin/ai-gemini $out/bin/gemini
    
    # Gemini nightly wrapper - ~/.npm-global/bin/gemini'yi çağırır
    cat > $out/bin/ai-gemini-nightly << 'EOF'
#!/usr/bin/env bash
NPM_PREFIX=$(npm config get prefix)
if [ -f "$NPM_PREFIX/bin/gemini" ]; then
    exec "$NPM_PREFIX/bin/gemini" "$@"
else
    echo "❌ Gemini nightly versiyonu kurulu değil!"
    echo "💡 Kurmak için: ai-gemini-update"
    exit 1
fi
EOF
    
    chmod +x $out/bin/ai-gemini-nightly
    
    # Gemini nightly update script
    cat > $out/bin/ai-gemini-update << 'EOF'
#!/usr/bin/env bash
set -e

echo "🔍 Gemini CLI için en son nightly sürüm kontrol ediliyor..."

# npm registry'den tüm versiyonları al ve en son nightly'yi bul
LATEST_NIGHTLY=$(npm view @google/gemini-cli versions --json 2>/dev/null | \
    grep -o '"[^"]*nightly[^"]*"' | \
    sed 's/"//g' | \
    sort -V | \
    tail -n1)

if [ -z "$LATEST_NIGHTLY" ]; then
    echo "❌ Nightly sürüm bilgisi alınamadı!"
    exit 1
fi

echo "📦 En son nightly sürüm: $LATEST_NIGHTLY"

# Kurulu sürümü npm global prefix'ten kontrol et
NPM_PREFIX=$(npm config get prefix)
if [ -f "$NPM_PREFIX/bin/gemini" ]; then
    CURRENT_VERSION=$($NPM_PREFIX/bin/gemini --version 2>/dev/null || echo "bilinmiyor")
    echo "💾 Kurulu sürüm: $CURRENT_VERSION"
    
    # Versiyon karşılaştırması
    if [ "$CURRENT_VERSION" = "$LATEST_NIGHTLY" ]; then
        echo "✅ Zaten en son nightly sürüm kurulu!"
        exit 0
    fi
else
    echo "💾 Gemini CLI henüz kurulu değil"
fi

echo ""
echo "⬇️  En son nightly sürüm kuruluyor..."

npm install -g "@google/gemini-cli@''${LATEST_NIGHTLY}"

echo ""
echo "✨ Güncelleme tamamlandı!"
echo "🎉 Yeni sürüm:"
$NPM_PREFIX/bin/gemini --version
EOF
    
    chmod +x $out/bin/ai-gemini-update
    
    runHook postInstall
  '';
  
  meta = with lib;
    {
      description = "AI agent that brings the power of Gemini directly into your terminal";
      longDescription = ''
        Gemini CLI is the official command-line interface for Google's Gemini AI.
        It provides interactive chat, code generation, and context-aware assistance
        directly from your terminal with Google account authentication.
        
        Commands:
        - ai-gemini: Official stable version (via npx)
        - ai-gemini-nightly: Latest nightly build (requires ai-gemini-update)
        - ai-gemini-update: Install/update to latest nightly version
      '';
      homepage = "https://github.com/google-gemini/gemini-cli";
      license = licenses.asl20;
      maintainers = with maintainers; [ ];
      platforms = platforms.unix;
      mainProgram = "ai-gemini";
    };
}
