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
    
    # Başlangıç modelleri
    defaultModels = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "deepseek-r1:8b" ];
      description = "List of models to load at startup";
    };
    
    # API port ayarı
    apiPort = lib.mkOption {
      type = lib.types.port;
      default = 11434;
      description = "Port for Ollama API to listen on";
    };
    
    # GPU kullanımı
    useGPU = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GPU acceleration";
    };
    
    # Model dizini
    modelDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.ollama/models";
      description = "Directory to store models";
    };
  };

  config = lib.mkIf cfg.enable {
    # Servis yapılandırması
    services.ollama = {
      enable = true;
      loadModels = cfg.defaultModels;
      environment = {
        OLLAMA_HOST = "127.0.0.1:${toString cfg.apiPort}";
        OLLAMA_MODELS = cfg.modelDir;
        CUDA_VISIBLE_DEVICES = if cfg.useGPU then "0" else "-1";
      };
    };

    # Python bağlayıcıları ve yardımcı araçlar
    home.packages = with pkgs; [
      python311Packages.ollama # Python API client
      # ollama-gui              # GUI arayüzü (paket mevcut değilse kaldırıldı)
      # cuda-tools              # CUDA araçları (paket adı doğrulanmalı)
    ];

    # Shell konfigürasyonu
    programs.zsh = {
      # Otomatik tamamlama desteği
      enableCompletion = true;
      
      # Shell aliases
      shellAliases = {
        "oll" = "ollama run";             # Hızlı model çalıştırma
        "oll-ls" = "ollama list";         # Model listesi
        "oll-pull" = "ollama pull";       # Model indirme
        "oll-rm" = "ollama rm";           # Model silme
        "oll-serve" = "ollama serve";     # API sunucusu başlatma
      };
      
      # Ollama completion'ı manuel olarak ekle
      initExtra = ''
        # Ollama completion (eğer mevcut ise)
        if command -v ollama >/dev/null 2>&1; then
          eval "$(ollama completion zsh 2>/dev/null || true)"
        fi
      '';
    };

    # Ortam değişkenleri
    home.sessionVariables = {
      OLLAMA_ORIGINS = "*";               # CORS ayarı
      OLLAMA_DEBUG = "0";                 # Debug modu
      OLLAMA_HOST = "127.0.0.1:${toString cfg.apiPort}";
    };
  };
}

