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
    
    # Shell configuration for claude command
    programs.zsh = mkIf (cfg.claude-cli.enable && config.programs.zsh.enable) {
      shellAliases = {
        claude = "${cfg.claude-cli.package}/bin/claude";
        ai = "${cfg.claude-cli.package}/bin/claude";
      };
    };
    
    programs.bash = mkIf (cfg.claude-cli.enable && config.programs.bash.enable) {
      shellAliases = {
        claude = "${cfg.claude-cli.package}/bin/claude";
        ai = "${cfg.claude-cli.package}/bin/claude";
      };
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

