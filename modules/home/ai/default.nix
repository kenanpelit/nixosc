# modules/home/ai/default.nix
# ==============================================================================
# Home module for AI tooling: CLI wrappers and helper binaries for LLM flows.
# Installs selected AI tools and exposes per-user settings in one place.
# Tweak model/runtime choices here instead of scattering shell snippets.
# ==============================================================================

{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.my.user.ai;
  aliases =
    mkMerge [
      (mkIf cfg.gemini-cli.enable {
        gemini = "${cfg.gemini-cli.package}/bin/ai-gemini";
        ai-gemini = "${cfg.gemini-cli.package}/bin/ai-gemini";
      })
      (mkIf cfg.codex-cli.enable {
        codex = "${cfg.codex-cli.package}/bin/ai-codex";
        ai-codex = "${cfg.codex-cli.package}/bin/ai-codex";
      })
    ];

  desktopEntries =
    mkMerge [
      (mkIf cfg.gemini-cli.enable {
        gemini-cli = {
          name = "Gemini CLI";
          comment = "Google's AI agent for your terminal";
          exec = "${cfg.gemini-cli.package}/bin/ai-gemini";
          icon = "terminal";
          terminal = true;
          categories = [ "Development" "ConsoleOnly" ];
        };
      })
      (mkIf cfg.codex-cli.enable {
        codex-cli = {
          name = "OpenAI Codex";
          comment = "OpenAI's AI coding agent";
          exec = "${cfg.codex-cli.package}/bin/ai-codex";
          icon = "terminal";
          terminal = true;
          categories = [ "Development" "ConsoleOnly" ];
        };
      })
    ];
in
{
  options.my.user.ai = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable AI tools and interfaces";
    };
    
    gemini-cli = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Gemini CLI";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.callPackage ./gemini-cli.nix { };
        description = "Gemini CLI package to use";
      };
    };
    
    codex-cli = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable OpenAI Codex CLI (requires ChatGPT Plus/Pro)";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.callPackage ./openai-cli.nix { };
        description = "OpenAI Codex CLI package to use";
      };
    };
    
    ollama = {
      enable = mkEnableOption "Ollama local AI models";
      models = mkOption {
        type = types.listOf types.str;
        default = [ "llama2" "codellama" ];
        description = "List of Ollama models to pre-install";
      };
    };
  };
  
  config = mkIf cfg.enable {
    home.packages = with pkgs;
      (optional cfg.gemini-cli.enable cfg.gemini-cli.package) ++
      (optional cfg.codex-cli.enable cfg.codex-cli.package);
    
    # Shell configuration for AI commands
    programs.zsh = mkIf config.programs.zsh.enable { shellAliases = aliases; };
    
    programs.bash = mkIf config.programs.bash.enable { shellAliases = aliases; };
    
    # Ollama service
    systemd.user.services.ollama = mkIf cfg.ollama.enable {
      Unit = {
        Description = "Ollama AI models service";
        After = [ "network.target" ];
      };
      
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.ollama}/bin/ollama serve";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = [
          "OLLAMA_HOST=127.0.0.1:11434"
        ];
      };
      
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
    
    # Environment variables
    home.sessionVariables = mkMerge [
      (mkIf cfg.ollama.enable {
        OLLAMA_HOST = "127.0.0.1:11434";
      })
    ];
    
    # Desktop entries
    xdg.desktopEntries = desktopEntries;

    xdg.configFile = { };
  };
}
