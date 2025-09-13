# modules/home/ai/default.nix
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.home.ai;
in
{
  options.modules.home.ai = {
    enable = mkEnableOption "AI tools and interfaces";
    
    claude-cli = {
      enable = mkEnableOption "Claude CLI (Claude Code)";
      package = mkOption {
        type = types.package;
        default = pkgs.callPackage ./claude-cli.nix { };
        description = "Claude CLI package to use";
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
      (optional cfg.ollama.enable ollama);

    programs.zsh.shellAliases = mkIf (cfg.claude-cli.enable && config.programs.zsh.enable) {
      claude = "claude";
      cc = "claude";
    };

    programs.bash.shellAliases = mkIf (cfg.claude-cli.enable && config.programs.bash.enable) {
      claude = "claude";
      cc = "claude";
    };

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

    home.sessionVariables = mkIf cfg.ollama.enable {
      OLLAMA_HOST = "127.0.0.1:11434";
    };

    xdg.desktopEntries = mkIf cfg.claude-cli.enable {
      claude-cli = {
        name = "Claude Code";
        comment = "Agentic coding tool from Anthropic";
        exec = "${cfg.claude-cli.package}/bin/claude";
        icon = "terminal";
        terminal = true;
        categories = [ "Development" "ConsoleOnly" ];
      };
    };
  };
}

