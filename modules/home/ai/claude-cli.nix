# modules/home/ai/claude-cli.nix
{ lib, stdenv, makeWrapper, nodejs }:

stdenv.mkDerivation rec {
  pname = "claude-code";
  version = "latest";

  src = builtins.toFile "dummy" "";

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nodejs ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin
    
    cat > $out/bin/claude << 'EOF'
#!/usr/bin/env bash
# HOME değişkenini ayarla
if [ -z "$HOME" ]; then
    export HOME=/tmp
fi

export NPM_CONFIG_CACHE="$HOME/.cache/npm"
export NPM_CONFIG_PREFIX="$HOME/.local"
mkdir -p "$HOME/.cache/npm" "$HOME/.local"

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
    echo "Node.js bulunamadı, nix shell kullanılıyor..."
    exec nix shell nixpkgs#nodejs_24 -c "$0" "$@"
}

# Node'u bul ve PATH'e ekle
find_node
export PATH="$NODE_BIN:$HOME/.local/bin:$PATH"

# npx ile en güncel sürümü çalıştır (versiyon belirtmeden)
exec "$NODE_BIN/npx" @anthropic-ai/claude-code "$@"
EOF
    
    chmod +x $out/bin/claude
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code - Agentic coding tool from Anthropic";
    homepage = "https://docs.anthropic.com/en/docs/claude-code";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}

