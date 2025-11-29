# modules/home/ai/openai-cli.nix
{ lib, stdenv, makeWrapper, nodejs }:
stdenv.mkDerivation rec {
  pname = "openai-codex-cli";
  version = "latest";
  
  src = builtins.toFile "dummy" "";
  
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nodejs ];
  
  dontUnpack = true;
  dontBuild = true;
  
  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin
    
    # OpenAI Codex CLI wrapper
    cat > $out/bin/ai-codex << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# HOME değişkenini ayarla
if [ -z "$HOME" ]; then
    export HOME=/tmp
fi

# NPM ayarları
export NPM_CONFIG_CACHE="$HOME/.cache/npm"
export NPM_CONFIG_PREFIX="$HOME/.local"
export NPM_CONFIG_UPDATE_NOTIFIER=false
export NO_UPDATE_NOTIFIER=1

# Dizinleri oluştur
mkdir -p "$HOME/.cache/npm" "$HOME/.local/bin" "$HOME/.local/lib"

# Node.js path'ini bul
find_node() {
    if command -v node >/dev/null 2>&1; then
        NODE_BIN=$(dirname $(command -v node))
        return 0
    fi
    
    for profile_path in /etc/profiles/per-user/*/bin /nix/var/nix/profiles/*/bin ~/.nix-profile/bin; do
        if [ -f "$profile_path/node" ]; then
            NODE_BIN="$profile_path"
            return 0
        fi
    done
    
    local latest_node=$(find /nix/store -maxdepth 1 -name "*nodejs*" -type d 2>/dev/null | \
                       grep -E "nodejs-[0-9]+\\.[0-9]+" | \
                       sort -V | tail -1)
    
    if [ -n "$latest_node" ] && [ -f "$latest_node/bin/node" ]; then
        NODE_BIN="$latest_node/bin"
        return 0
    fi
    
    echo "Node.js bulunamadı, nix shell kullanılıyor..." >&2
    exec nix shell nixpkgs#nodejs_24 -c "$0" "$@"
}

find_node
export PATH="$NODE_BIN:$HOME/.local/bin:$PATH"

# OpenAI Codex CLI'yi npx ile çalıştır
exec "$NODE_BIN/npx" --yes @openai/codex "$@"
EOF
    
    chmod +x $out/bin/ai-codex
    
    # Alias: codex -> ai-codex
    ln -s $out/bin/ai-codex $out/bin/codex
    
    runHook postInstall
  '';
  
  meta = with lib;
    {
      description = "OpenAI Codex CLI - AI coding agent for your terminal";
      longDescription = ''
        Codex CLI is a coding agent that you can run locally from your terminal.
        It can read, modify, and run code on your machine in the chosen directory.
        Built in Rust for speed and efficiency.
        
        Requires OpenAI API access (ChatGPT Plus, Pro, Business, Edu, or Enterprise).
        
        Commands:
        - ai-codex: OpenAI Codex CLI
        - codex: Alias for ai-codex
        
        First time setup: codex (will guide you through authentication)
      '';
      homepage = "https://developers.openai.com/codex/cli";
      license = licenses.unfree;
      maintainers = with maintainers; [ ];
      platforms = platforms.unix;
      mainProgram = "ai-codex";
    };
}
