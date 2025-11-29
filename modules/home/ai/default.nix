# modules/home/ai/default.nix
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.home.ai;
in
{
  options.modules.home.ai = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable AI tools and interfaces";
    };
    
    claude-cli = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Claude CLI (Claude Code)";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.callPackage ./claude-cli.nix { };
        description = "Claude CLI package to use";
      };
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
      (optional cfg.claude-cli.enable cfg.claude-cli.package) ++
      (optional cfg.gemini-cli.enable cfg.gemini-cli.package) ++
      (optional cfg.codex-cli.enable cfg.codex-cli.package);
    
    # Shell configuration for AI commands
    programs.zsh = mkIf config.programs.zsh.enable {
      shellAliases = mkMerge [
        (mkIf cfg.claude-cli.enable {
          claude = "${cfg.claude-cli.package}/bin/claude";
          ai-claude = "${cfg.claude-cli.package}/bin/claude";
        })
        (mkIf cfg.gemini-cli.enable {
          gemini = "${cfg.gemini-cli.package}/bin/ai-gemini";
          ai-gemini = "${cfg.gemini-cli.package}/bin/ai-gemini";
        })
        (mkIf cfg.codex-cli.enable {
          codex = "${cfg.codex-cli.package}/bin/ai-codex";
          ai-codex = "${cfg.codex-cli.package}/bin/ai-codex";
        })
      ];
    };
    
    programs.bash = mkIf config.programs.bash.enable {
      shellAliases = mkMerge [
        (mkIf cfg.claude-cli.enable {
          claude = "${cfg.claude-cli.package}/bin/claude";
          ai-claude = "${cfg.claude-cli.package}/bin/claude";
        })
        (mkIf cfg.gemini-cli.enable {
          gemini = "${cfg.gemini-cli.package}/bin/ai-gemini";
          ai-gemini = "${cfg.gemini-cli.package}/bin/ai-gemini";
        })
        (mkIf cfg.codex-cli.enable {
          codex = "${cfg.codex-cli.package}/bin/ai-codex";
          ai-codex = "${cfg.codex-cli.package}/bin/ai-codex";
        })
      ];
    };
    
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
    home.sessionVariables = mkIf cfg.ollama.enable {
      OLLAMA_HOST = "127.0.0.1:11434";
    };
    
    # Desktop entries
    xdg.desktopEntries = mkMerge [
      (mkIf cfg.claude-cli.enable {
        claude-cli = {
          name = "Claude Code";
          comment = "Anthropic's agentic coding tool";
          exec = "${cfg.claude-cli.package}/bin/claude";
          icon = "terminal";
          terminal = true;
          categories = [ "Development" "ConsoleOnly" ];
        };
      })
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
  };
}
