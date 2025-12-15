# modules/home/ollama/default.nix
# ==============================================================================
# Home module for Ollama local LLM runtime.
# Installs ollama client and controls user service flags.
# Manage model runtime options here instead of manual service setup.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.ollama;
in {
  options.my.user.ollama = {
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
      # loadModels = cfg.defaultModels; # Bu seçenek de olmayabilir, kontrol etmek lazım ama şimdilik kalsın
    };

    # Python bindings and utilities
    home.packages = with pkgs; [
      python311Packages.ollama # Python API client
    ];

    # Environment variables
    home.sessionVariables = {
      OLLAMA_ORIGINS = "*";               # CORS setting
      OLLAMA_DEBUG = "0";                 # Debug mode
      OLLAMA_HOST = "127.0.0.1:${toString cfg.apiPort}";
      OLLAMA_MODELS = cfg.modelDir;
      CUDA_VISIBLE_DEVICES = if cfg.useGPU then "0" else "-1";
    };
  };
}
