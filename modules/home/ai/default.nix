# modules/home/ai/default.nix
# ==============================================================================
# AI Tools & CLI Integration
# ==============================================================================
# Purpose:
#   - Provide a unified way to enable / disable AI CLIs (Claude, Gemini, Codex).
#   - Optionally run a local Ollama service with model presets.
# Notes:
#   - Core GUI / editor integration lives in other modules (e.g. nvim, browsers).
#   - This module focuses on terminal workflows and background services.
# ==============================================================================
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.home.ai;
  aliases =
    mkMerge [
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
      (mkIf cfg.every-code.enable {
        code = "${cfg.every-code.package}/bin/code";
        "ai-code-gemini" = "${cfg.every-code.package}/bin/code -m gemini-3-pro";
        "ai-code-gpt" = "${cfg.every-code.package}/bin/code";
      })
    ];

  desktopEntries =
    mkMerge [
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
      (mkIf cfg.every-code.enable {
        every-code = {
          name = "Every Code";
          comment = "Every Code (code) – local coding agent";
          exec = "${cfg.every-code.package}/bin/code";
          icon = "terminal";
          terminal = true;
          categories = [ "Development" "ConsoleOnly" ];
        };
      })
    ];
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

    every-code = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Every Code (code) CLI orchestrator";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.callPackage ./code-cli.nix { };
        description = "Every Code CLI package to use (@just-every/code).";
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
      (optional cfg.codex-cli.enable cfg.codex-cli.package) ++
      (optional cfg.every-code.enable cfg.every-code.package);
    
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
      (mkIf cfg.every-code.enable {
        CODE_HOME = "${config.xdg.configHome}/code";
      })
    ];
    
    # Desktop entries
    xdg.desktopEntries = desktopEntries;

    # Every Code configuration (uses CODE_HOME, which we point to XDG config)
    # Use force = true so Home Manager can safely overwrite an existing
    # config/backup pair without failing activation.
    xdg.configFile = mkIf cfg.every-code.enable {
      "code/config.toml" = {
        force = true;
        text = ''
          model = "gpt-5.1"
          model_provider = "openai"
          approval_policy = "on-request"
          model_reasoning_effort = "medium"
          sandbox_mode = "workspace-write"

          [tui.theme]
          # Valid themes include:
          #   light-photon, light-photon-ansi16, light-prism-rainbow,
          #   light-vivid-triad, light-porcelain, light-sandbar, light-glacier,
          #   dark-carbon-night, dark-carbon-ansi16, dark-shinobi-dusk,
          #   dark-oled-black-pro, dark-amber-terminal, dark-aurora-flux,
          #   dark-charcoal-rainbow, dark-zen-garden, dark-paper-light-pro, custom
          name = "dark-aurora-flux"

          # Default OpenAI profile
          [profiles.gpt-5]
          model = "gpt-5.1"
          model_provider = "openai"
          approval_policy = "never"
          model_reasoning_effort = "high"

          # NOTE: Gemini 3 is currently used within Every Code via CLI agent
          # (Agents » gemini-3-pro, Command=gemini).
          # Writing model = "gemini-3-pro(-preview)" here causes Code to
          # call an unknown model via the OpenAI provider,
          # resulting in a 400 model_not_found error.
          #
          # If valid `model_provider` and `model` strings for Gemini
          # are published in official documentation in the future,
          # it is safer to manually uncomment and fill the block below:
          #
          # [profiles.gemini-3]
          # model = "gemini-3-pro-preview"
          # model_provider = "<gemini-provider>" # e.g. google / gemini (see docs or /settings)
          # approval_policy = "on-request"
          # model_reasoning_effort = "medium"
        '';
      };
    };
  };
}
