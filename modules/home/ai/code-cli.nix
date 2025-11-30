# modules/home/ai/code-cli.nix
# ==============================================================================
# Every Code (code) - Nix wrapper around @just-every/code
# ==============================================================================
{ lib, stdenv, makeWrapper, nodejs }:

stdenv.mkDerivation rec {
  pname = "code-cli";
  version = "latest";

  src = builtins.toFile "dummy" "";

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nodejs ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"

    cat > "$out/bin/code" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Ensure HOME is set
if [ -z "${HOME:-}" ]; then
  export HOME=/tmp
fi

# NPM configuration (local, quiet)
export NPM_CONFIG_CACHE="$HOME/.cache/npm"
export NPM_CONFIG_PREFIX="$HOME/.local"
export NPM_CONFIG_UPDATE_NOTIFIER=false
export NO_UPDATE_NOTIFIER=1

mkdir -p "$HOME/.cache/npm" "$HOME/.local/bin" "$HOME/.local/lib"

# Add nodejs to PATH
export PATH="${nodejs}/bin:$HOME/.local/bin:$PATH"

# Exec npx
exec "${nodejs}/bin/npx" --yes @just-every/code "$@"
EOF

    chmod +x "$out/bin/code"

    runHook postInstall
  '';

  meta = with lib;
    {
      description = "Every Code CLI - fast local coding agent (@just-every/code)";
      # Long description omitted to keep the derivation shell-safe.
      homepage = "https://github.com/just-every/code";
      license = licenses.asl20;
      maintainers = [ ];
      platforms = platforms.unix;
      mainProgram = "code";
    };
}
