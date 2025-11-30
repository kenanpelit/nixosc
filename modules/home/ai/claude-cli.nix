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
    
    cat > $out/bin/claude << EOF
#!/usr/bin/env bash
set -e

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

export PATH="${nodejs}/bin:$HOME/.local/bin:$PATH"

# Run latest version via npx (without specifying version)
exec "${nodejs}/bin/npx" --yes @anthropic-ai/claude-code "$@"
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