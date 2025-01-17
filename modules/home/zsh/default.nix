# modules/home/zsh/default.nix
# ==============================================================================
# ZSH Configuration Root
# ==============================================================================
{ hostname, config, pkgs, host, ... }:
{
 # =============================================================================
 # Module Imports
 # =============================================================================
 imports = [
   ./zsh.nix           # Core ZSH configuration
   ./zsh_aliases.nix   # Shell aliases
   ./zsh_functions.nix # Custom functions
   ./zsh_keybinds.nix  # Key bindings
   ./zsh_plugins.nix   # Plugins
   ./completions       # Tab completion settings
 ];
}
