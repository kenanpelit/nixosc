# modules/home/ollama/default.nix
# ==============================================================================
# Ollama LLM Configuration
# ==============================================================================
# This configuration manages Ollama LLM settings including:
# - Service configuration and model management
# - GPU acceleration settings
# - Shell aliases and environment variables
# - API and network configuration
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.home.ollama;
in {
  options.modules.home.ollama = {
    enable = lib.mkEnableOption "ollama configuration";
    
    # Startup models
    defaultModels = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "deepseek-r1:8b" ];
      description = "List of models to load at startup";
    };
    
    # API port setting
    apiPort = lib.mkOption {
      type = lib.types.port;
      default = 11434;
      description = "Port for Ollama API to listen on";
    };
    
    # GPU usage
    useGPU = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GPU acceleration";
    };
    
    # Model directory
    modelDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.ollama/models";
      description = "Directory to store models";
    };
  };

  config = lib.mkIf cfg.enable {
    # Service configuration
    services.ollama = {
      enable = true;
      loadModels = cfg.defaultModels;
      environment = {
        OLLAMA_HOST = "127.0.0.1:${toString cfg.apiPort}";
        OLLAMA_MODELS = cfg.modelDir;
        CUDA_VISIBLE_DEVICES = if cfg.useGPU then "0" else "-1";
      };
    };

    # Python bindings and utilities
    home.packages = with pkgs; [
      python311Packages.ollama # Python API client
      # ollama-gui              # GUI interface (removed if package unavailable)
      # cuda-tools              # CUDA tools (verify package name)
    ];

    # Shell configuration
    programs.zsh = {
      # Completion support
      enableCompletion = true;
      
      # Shell aliases
      shellAliases = {
        "oll" = "ollama run";             # Quick model run
        "oll-ls" = "ollama list";         # List models
        "oll-pull" = "ollama pull";       # Download model
        "oll-rm" = "ollama rm";           # Delete model
        "oll-serve" = "ollama serve";     # Start API server
      };
      
      # Manually add Ollama completion
      initExtra = ''
        # Ollama completion (if available)
        if command -v ollama >/dev/null 2>&1; then
          eval "$(ollama completion zsh 2>/dev/null || true)"
        fi
      '';
    };

    # Environment variables
    home.sessionVariables = {
      OLLAMA_ORIGINS = "*";               # CORS setting
      OLLAMA_DEBUG = "0";                 # Debug mode
      OLLAMA_HOST = "127.0.0.1:${toString cfg.apiPort}";
    };
  };
}