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
    
    chatgpt-cli = {
      enable = mkEnableOption "ChatGPT CLI interface";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Claude CLI
      (mkIf cfg.claude-cli.enable cfg.claude-cli.package)
      
      # Ollama
      (mkIf cfg.ollama.enable ollama)
      
      # ChatGPT CLI (community package)
      (mkIf cfg.chatgpt-cli.enable (pkgs.python3Packages.buildPythonApplication rec {
        pname = "chatgpt-cli";
        version = "1.4.2";
        
        src = pkgs.fetchPypi {
          inherit pname version;
          sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        };
        
        propagatedBuildInputs = with pkgs.python3Packages; [
          requests
          click
          rich
        ];
        
        meta = with lib; {
          description = "ChatGPT CLI interface";
          license = licenses.mit;
        };
      }))
    ];

    # Claude CLI için shell aliases
    programs.zsh.shellAliases = mkIf (cfg.claude-cli.enable && config.programs.zsh.enable) {
      claude = "claude-cli";
      cc = "claude-cli";
    };

    programs.bash.shellAliases = mkIf (cfg.claude-cli.enable && config.programs.bash.enable) {
      claude = "claude-cli";
      cc = "claude-cli";
    };

    # Ollama için systemd user service
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
      };
      
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # AI araçları için environment variables
    home.sessionVariables = mkIf cfg.enable {
      OLLAMA_HOST = "127.0.0.1:11434";
    };

    # XDG desktop entries
    xdg.desktopEntries = mkIf cfg.claude-cli.enable {
      claude-cli = {
        name = "Claude CLI";
        comment = "Command-line interface for Claude AI";
        exec = "${cfg.claude-cli.package}/bin/claude";
        icon = "terminal";
        terminal = true;
        categories = [ "Development" "ConsoleOnly" ];
      };
    };
  };
}
