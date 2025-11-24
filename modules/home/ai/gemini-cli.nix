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
    
    cat > $out/bin/gemini << 'EOF'
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
                       grep -E "nodejs-[0-9]+\.[0-9]+" | \
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
    
    chmod +x $out/bin/gemini
    
    runHook postInstall
  '';
  
  meta = with lib; {
    description = "AI agent that brings the power of Gemini directly into your terminal";
    longDescription = ''
      Gemini CLI is the official command-line interface for Google's Gemini AI.
      It provides interactive chat, code generation, and context-aware assistance
      directly from your terminal with Google account authentication.
    '';
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "gemini";
  };
}
