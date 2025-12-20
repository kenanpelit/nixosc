# modules/home/ai/gemini-cli.nix
# ==============================================================================
# Google Gemini CLI wrapper: builds a sandboxed npx-based launcher, exposes
# ai-gemini/gemini binaries, and ships nightly/update helpers. Assumes
# Google API access is configured.
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
if [ -z "''${HOME:-}" ]; then
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
    VERSION=$("$NPM_PREFIX/bin/gemini" --version 2>/dev/null || true)
    if echo "$VERSION" | grep -qi "nightly"; then
        exec "$NPM_PREFIX/bin/gemini" "$@"
    fi
    echo "❌ Installed Gemini CLI is not a nightly build: ''${VERSION:-unknown}"
    echo "💡 To install nightly: ai-gemini-update nightly"
    exit 1
else
    echo "❌ Gemini nightly version is not installed!"
    echo "💡 To install: ai-gemini-update nightly"
    exit 1
fi
EOF
    
    chmod +x $out/bin/ai-gemini-nightly
    
# Gemini nightly update script
    cat > $out/bin/ai-gemini-update << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
export PATH="${nodejs}/bin:$HOME/.local/bin:$PATH"
export NPM_CONFIG_PREFIX="$HOME/.local"

CHANNEL="''${1:-stable}"

echo "🔍 Checking for latest Gemini CLI version (channel: $CHANNEL)..."

get_dist_tag() {
  local tag="''${1}"
  npm view @google/gemini-cli dist-tags --json 2>/dev/null \
    | grep -E "\"''${tag}\"" \
    | sed -n "s/.*\"''${tag}\":[[:space:]]*\"\\([^\"]\\+\\)\".*/\\1/p" \
    | head -n1
}

get_latest_for_channel() {
  case "$CHANNEL" in
    stable|latest)
      get_dist_tag "latest"
      ;;
    preview|next|beta)
      # Gemini CLI uses preview releases (e.g. 0.22.0-preview.3). On npm this is
      # commonly published under the "next" dist-tag. Keep fallbacks.
      get_dist_tag "next" || true
      ;;
    nightly)
      get_dist_tag "nightly" || true
      ;;
    *)
      echo "❌ Unknown channel: $CHANNEL"
      echo "💡 Usage: ai-gemini-update [stable|preview|nightly]"
      exit 2
      ;;
  esac
}

LATEST="$(get_latest_for_channel)"

# Fallbacks when dist-tags are missing or the registry blocks dist-tags.
if [[ -z "''${LATEST:-}" ]]; then
  ALL_VERSIONS_JSON="$(npm view @google/gemini-cli versions --json 2>/dev/null || true)"
  case "$CHANNEL" in
    stable|latest)
      # Pick the highest "plain" semver (no prerelease suffixes).
      LATEST="$(
        echo "$ALL_VERSIONS_JSON" \
          | grep -oE '"[0-9]+\.[0-9]+\.[0-9]+"' \
          | tr -d '"' \
          | sort -V \
          | tail -n1
      )"
      ;;
    preview|next|beta)
      LATEST="$(
        echo "$ALL_VERSIONS_JSON" \
          | grep -oE '"[0-9]+\.[0-9]+\.[0-9]+-preview\.[0-9]+"' \
          | tr -d '"' \
          | sort -V \
          | tail -n1
      )"
      ;;
    nightly)
      LATEST="$(
        echo "$ALL_VERSIONS_JSON" \
          | grep -o '"[^"]*nightly[^"]*"' \
          | tr -d '"' \
          | sort -V \
          | tail -n1
      )"
      ;;
  esac
fi

if [[ -z "''${LATEST:-}" ]]; then
  echo "❌ Could not resolve latest version for channel: $CHANNEL"
  echo "💡 Try: npm view @google/gemini-cli dist-tags"
  exit 1
fi

echo "📦 Latest version: $LATEST"

NPM_PREFIX="$HOME/.local"
mkdir -p "$NPM_PREFIX/bin"

if [ -f "$NPM_PREFIX/bin/gemini" ]; then
    CURRENT_VERSION=$("$NPM_PREFIX/bin/gemini" --version 2>/dev/null || echo "unknown")
    echo "💾 Installed version: $CURRENT_VERSION"
    
    if [ "$CURRENT_VERSION" = "$LATEST" ]; then
        echo "✅ Latest version is already installed!"
        exit 0
    fi
else
    echo "💾 Gemini CLI is not installed yet"
fi

echo ""
echo "⬇️  Installing $CHANNEL version: $LATEST ..."

npm install -g "@google/gemini-cli@''${LATEST}"

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
        - ai-gemini-nightly: Latest nightly build (requires ai-gemini-update nightly)
        - ai-gemini-update: Install/update Gemini CLI (stable/preview/nightly)
      '';
      homepage = "https://github.com/google-gemini/gemini-cli";
      license = licenses.asl20;
      maintainers = with maintainers; [ ];
      platforms = platforms.unix;
      mainProgram = "ai-gemini";
    };
}
