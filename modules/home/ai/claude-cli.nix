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
set -e

# Set HOME variable
if [ -z "$HOME" ]; then
    export HOME=/tmp
fi

# NPM settings - user local dirs and suppress warnings
export NPM_CONFIG_CACHE="$HOME/.cache/npm"
export NPM_CONFIG_PREFIX="$HOME/.local"
export NPM_CONFIG_UPDATE_NOTIFIER=false
export NO_UPDATE_NOTIFIER=1

# Create directories
mkdir -p "$HOME/.cache/npm" "$HOME/.local/bin" "$HOME/.local/lib"

# Find nodejs path dynamically
find_node() {
    # First try node in PATH
    if command -v node >/dev/null 2>&1; then
        NODE_BIN=$(dirname $(command -v node))
        return 0
    fi
    
    # Search node in Nix profiles
    for profile_path in /etc/profiles/per-user/*/bin /nix/var/nix/profiles/*/bin ~/.nix-profile/bin; do
        if [ -f "$profile_path/node" ]; then
            NODE_BIN="$profile_path"
            return 0
        fi
    done
    
    # Find latest nodejs in Nix store
    local latest_node=$(find /nix/store -maxdepth 1 -name "*nodejs*" -type d 2>/dev/null | \
                       grep -E "nodejs-[0-9]+\\.[0-9]+" | \
                       sort -V | tail -1)
    
    if [ -n "$latest_node" ] && [ -f "$latest_node/bin/node" ]; then
        NODE_BIN="$latest_node/bin"
        return 0
    fi
    
    # Last resort: run via nix shell
    echo "Node.js not found, using nix shell..." >&2
    exec nix shell nixpkgs#nodejs_24 -c "$0" "$@"
}

# Find Node and add to PATH
find_node
export PATH="$NODE_BIN:$HOME/.local/bin:$PATH"

# Run latest version via npx (without specifying version)
# Add 2>/dev/null to suppress npm warnings if desired
exec "$NODE_BIN/npx" --yes @anthropic-ai/claude-code "$@"
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