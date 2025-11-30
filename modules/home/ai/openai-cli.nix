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

# Ensure HOME is set (avoid empty HOME in some sandboxed shells)
if [ -z "${HOME:-}" ]; then
  export HOME=/tmp
fi

# NPM ayarları
export NPM_CONFIG_CACHE="$HOME/.cache/npm"
export NPM_CONFIG_PREFIX="$HOME/.local"
export NPM_CONFIG_UPDATE_NOTIFIER=false
export NO_UPDATE_NOTIFIER=1

# Dizinleri oluştur
mkdir -p "$HOME/.cache/npm" "$HOME/.local/bin" "$HOME/.local/lib"

export PATH="${nodejs}/bin:$HOME/.local/bin:$PATH"

# OpenAI Codex CLI'yi npx ile çalıştır
exec "${nodejs}/bin/npx" --yes @openai/codex "$@"
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
