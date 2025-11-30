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
if [ -z "$HOME" ]; then
  export HOME=/tmp
fi

# NPM configuration (local, quiet)
export NPM_CONFIG_CACHE="$HOME/.cache/npm"
export NPM_CONFIG_PREFIX="$HOME/.local"
export NPM_CONFIG_UPDATE_NOTIFIER=false
export NO_UPDATE_NOTIFIER=1

mkdir -p "$HOME/.cache/npm" "$HOME/.local/bin" "$HOME/.local/lib"

find_node() {
  if command -v node >/dev/null 2>&1; then
    NODE_BIN="$(dirname "$(command -v node)")"
    return 0
  fi

  for profile_path in /etc/profiles/per-user/*/bin /nix/var/nix/profiles/*/bin "$HOME/.nix-profile/bin"; do
    if [ -f "$profile_path/node" ]; then
      NODE_BIN="$profile_path"
      return 0
    fi
  done

  local latest_node
  latest_node="$(find /nix/store -maxdepth 1 -name "*nodejs*" -type d 2>/dev/null | \
    grep -E "nodejs-[0-9]+\\.[0-9]+" | \
    sort -V | tail -1 || true)"

  if [ -n "$latest_node" ] && [ -f "$latest_node/bin/node" ]; then
    NODE_BIN="$latest_node/bin"
    return 0
  fi

  echo "Node.js bulunamadı, nix shell kullanılıyor..." >&2
  exec nix shell nixpkgs#nodejs_24 -c "$0" "$@"
}

find_node
export PATH="$NODE_BIN:$HOME/.local/bin:$PATH"

exec "$NODE_BIN/npx" --yes @just-every/code "$@"
EOF

    chmod +x "$out/bin/code"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Every Code CLI - fast local coding agent (@just-every/code)";
    longDescription = ''
      Every Code (code) is a fast, local coding agent for your terminal.
      This wrapper runs the official @just-every/code package via npx, using
      a user-local npm prefix for caches and binaries.
    '';
    homepage = "https://github.com/just-every/code";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "code";
  };
}
