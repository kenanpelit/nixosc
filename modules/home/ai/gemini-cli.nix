# modules/home/ai/gemini-cli.nix
# ==============================================================================
# Google Gemini CLI Wrapper
# ==============================================================================
# Provides a Nix wrapper for the official Google Gemini CLI tool.
# - Installs the CLI tool using npx within a sandboxed environment.
# - Ensures Node.js and npm are correctly configured.
# - Creates `ai-gemini` and `gemini` executables in the user's PATH.
# - Includes scripts for managing nightly builds (`ai-gemini-nightly`, `ai-gemini-update`).
#
# Requires Google API access.
# ==============================================================================

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
# Set HOME variable
if [ -z "${HOME:-}" ]; then
    export HOME=/tmp
fi
# NPM settings - user local dirs and suppress warnings
export NPM_CONFIG_CACHE="$HOME/.cache/npm"
export NPM_CONFIG_PREFIX="$HOME/.local"
export NPM_CONFIG_UPDATE_NOTIFIER=false
export NO_UPDATE_NOTIFIER=1
# Create directories
mkdir -p "$HOME/.cache/npm" "$HOME/.local/bin" "$HOME/.local/lib"

# Add nodejs to PATH
export PATH="${nodejs}/bin:$HOME/.local/bin:$PATH"

# Run @google/gemini-cli via npx (official Google Gemini CLI)
exec "${nodejs}/bin/npx" --yes @google/gemini-cli "$@"
EOF
    
    chmod +x $out/bin/ai-gemini

    # Provide a plain `gemini` binary so tools like Every Code
    # (code) can discover the CLI via `gemini --version`.
    ln -s $out/bin/ai-gemini $out/bin/gemini
    
    # Gemini nightly wrapper
    cat > $out/bin/ai-gemini-nightly << 'EOF'
#!/usr/bin/env bash
export PATH="${nodejs}/bin:$HOME/.local/bin:$PATH"
NPM_PREFIX="$HOME/.local"

if [ -f "$NPM_PREFIX/bin/gemini" ]; then
    exec "$NPM_PREFIX/bin/gemini" "$@"
else
    echo "❌ Gemini nightly version is not installed!"
    echo "💡 To install: ai-gemini-update"
    exit 1
fi
EOF
    
    chmod +x $out/bin/ai-gemini-nightly
    
# Gemini nightly update script
    cat > $out/bin/ai-gemini-update << 'EOF'
#!/usr/bin/env bash
set -e
export PATH="${nodejs}/bin:$HOME/.local/bin:$PATH"
export NPM_CONFIG_PREFIX="$HOME/.local"

echo "🔍 Checking for latest Gemini CLI nightly version..."

# Get all versions from npm registry and find latest nightly
LATEST_NIGHTLY=$(npm view @google/gemini-cli versions --json 2>/dev/null |
    grep -o '"[^"]*nightly[^"]*"' |
    sed 's/"//g' |
    sort -V |
    tail -n1)

if [ -z "$LATEST_NIGHTLY" ]; then
    echo "❌ Could not get nightly version info!"
    exit 1
fi

echo "📦 Latest nightly version: $LATEST_NIGHTLY"

NPM_PREFIX="$HOME/.local"
mkdir -p "$NPM_PREFIX/bin"

if [ -f "$NPM_PREFIX/bin/gemini" ]; then
    CURRENT_VERSION=$("$NPM_PREFIX/bin/gemini" --version 2>/dev/null || echo "unknown")
    echo "💾 Installed version: $CURRENT_VERSION"
    
    if [ "$CURRENT_VERSION" = "$LATEST_NIGHTLY" ]; then
        echo "✅ Latest nightly version is already installed!"
        exit 0
    fi
else
    echo "💾 Gemini CLI is not installed yet"
fi

echo ""
echo "⬇️  Installing latest nightly version..."

npm install -g "@google/gemini-cli@''${LATEST_NIGHTLY}"

echo ""
echo "✨ Update complete!"
echo "🎉 New version:"
"$NPM_PREFIX/bin/gemini" --version
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
