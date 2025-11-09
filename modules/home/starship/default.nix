# modules/home/starship/default.nix
# ==============================================================================
# Starship Prompt — Catppuccin Mocha + Pure-like Layout (Performance Optimized)
# Author: Kenan Pelit
# Description:
#   • Dual-profile: FAST (default) vs FULL
#   • Aggressive I/O & subprocess reduction in FAST
#   • Clean, low-latency experience on large git repos / remote FS
# ==============================================================================

{ config, lib, pkgs, ... }:

let
  # ----------------------------------------------------------------------------
  # Profile switch
  # - Default: FAST (unless STARSHIP_MODE=full)
  # - You can still hardcode: fastMode = true/false
  # ----------------------------------------------------------------------------
  fastMode = builtins.getEnv "STARSHIP_MODE" != "full";

  # ----------------------------------------------------------------------------
  # Tunables (keep conservative to avoid "timed out" blanks on slow FS)
  # ----------------------------------------------------------------------------
  commandTimeout = if fastMode then 400 else 800;  # ms
  scanTimeout    = if fastMode then 12  else 30;   # ms

  # Feature toggles
  enableGitState       = !fastMode;  # rebase/merge state is expensive
  enableHeavyLanguages = !fastMode;  # Java/Ruby/... scans
  enableInfraTools     = !fastMode;  # Docker/Terraform/AWS/Package/Conda
  enableBattery        = !fastMode;  # show battery only in FULL

  # ----------------------------------------------------------------------------
  # Catppuccin Mocha Palette
  # ----------------------------------------------------------------------------
  catppuccinPalette = {
    rosewater = "#f5e0dc"; flamingo  = "#f2cdcd"; pink      = "#f5c2e7";
    mauve     = "#cba6f7"; red       = "#f38ba8"; maroon    = "#eba0ac";
    peach     = "#fab387"; yellow    = "#f9e2af"; green     = "#a6e3a1";
    teal      = "#94e2d5"; sky       = "#89dceb"; sapphire  = "#74c7ec";
    blue      = "#89b4fa"; lavender  = "#b4befe"; text      = "#cdd6f4";
    subtext1  = "#bac2de"; subtext0  = "#a6adc8"; overlay2  = "#9399b2";
    overlay1  = "#7f849c"; overlay0  = "#6c7086"; surface2  = "#585b70";
    surface1  = "#45475a"; surface0  = "#313244"; base      = "#1e1e2e";
    mantle    = "#181825"; crust     = "#11111b";
  };

  # ----------------------------------------------------------------------------
  # Layout presets
  # ----------------------------------------------------------------------------
  fastFormat = lib.concatStrings [
    # Line 1: Context + Git + core langs
    "$username$hostname$directory"
    "$git_branch$git_status"
    "$python$rust$golang$nodejs"
    "$nix_shell"
    "$cmd_duration"
    "$line_break"
    # Line 2: Jobs + prompt
    "$jobs$character"
  ];

  fullFormat = lib.concatStrings [
    # Line 1: Full context + git state + all langs
    "$username$hostname$directory"
    "$git_branch$git_status$git_state"
    "$python$rust$golang$nodejs$java$c$ruby$php$lua$haskell$elixir$zig"
    "$nix_shell"
    # Infra + pkg managers
    "$docker_context$terraform$aws"
    "$package$conda"
    "$cmd_duration"
    "$line_break"
    # Line 2: System info
    "$jobs$battery$status$character"
  ];

  # ----------------------------------------------------------------------------
  # DRY helpers
  # ----------------------------------------------------------------------------

  # Git config (spaces at tail to prevent tokens sticking together)
  gitConfig = {
    branch = {
      format             = "[$symbol$branch]($style) ";
      # Nerd Font symbol; falls back gracefully if font missing (just a square).
      symbol             = " ";
      style              = "bold mauve";
      truncation_length  = 15;
      truncation_symbol  = "…";
    };

    status = {
      format            = "[$all_status$ahead_behind]($style) ";
      style             = "bold red";
      ahead             = "⇡$count";
      behind            = "⇣$count";
      diverged          = "⇕";
      conflicted        = "═";
      deleted           = "✘";
      renamed           = "»";
      modified          = "!";
      staged            = "+";
      untracked         = "?";
      stashed           = "$";
      ignore_submodules = true;   # major win on mono-repos
    };

    state = {
      format   = "[$state( $progress_current/$progress_total)]($style) ";
      style    = "bold yellow";
      disabled = !enableGitState;
    };
  };

  # Language module template (trailing space!)
  mkLanguage = { symbol, style, extensions, files ? [], folders ? [] }: {
    format            = "[$symbol$version]($style) ";
    inherit symbol style;
    detect_extensions = extensions;
    detect_files      = files;
    detect_folders    = folders;
  };

in
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # ========================================================================
      # Core performance
      # ========================================================================
      command_timeout = commandTimeout;
      scan_timeout    = scanTimeout;
      add_newline     = true;

      # Profile-aware layout
      format = if fastMode then fastFormat else fullFormat;

      # Palette
      palette = "catppuccin_mocha";
      palettes.catppuccin_mocha = catppuccinPalette;

      # ========================================================================
      # Core prompt atoms
      # ========================================================================
      character = {
        success_symbol        = "[❯](bold mauve)";
        error_symbol          = "[❯](bold red)";
        vimcmd_symbol         = "[❮](bold lavender)";
        vimcmd_visual_symbol  = "[❮](bold pink)";
        vimcmd_replace_symbol = "[❮](bold mauve)";
      };

      username = {
        format      = "[$user]($style) ";
        style_user  = "bold sapphire";
        style_root  = "bold red";
        show_always = false;  # show on SSH or root
      };

      hostname = {
        ssh_only   = true;
        ssh_symbol = "↗ ";
        format     = "[@$hostname]($style) ";
        style      = "bold blue";
      };

      directory = {
        format            = "[$path]($style) ";
        style             = "bold sapphire";
        truncation_length = 3;     # keep a bit more context than 2
        truncation_symbol = "…/";
        truncate_to_repo  = true;
        read_only         = " ";
        read_only_style   = "red";

        # Minimal, fast substitutions (emoji/nerd fonts add tiny render cost)
        substitutions = {
          "Documents" = " ";   # document
          "Downloads" = " ";   # download
          "Music"     = " ";   # music
          "Pictures"  = " ";   # image
          "Videos"    = " ";   # film
          "Projects"  = " ";   # folder (devicons)
          "Desktop"   = " ";   # desktop
          ".config"   = " ";   # config (gear)
          ".nixosc"   = " ";   # Nix/NixOS logo
        };
      };

      # ========================================================================
      # Git (latency hotspot)
      # ========================================================================
      git_branch = gitConfig.branch;
      git_status = gitConfig.status;
      git_state  = gitConfig.state;

      # ========================================================================
      # Core languages (always on)
      # ========================================================================
      python = mkLanguage {
        symbol = " ";
        style  = "yellow";
        extensions = [ "py" ];
        files      = [ "requirements.txt" "pyproject.toml" "Pipfile" ".python-version" "tox.ini" "setup.py" "__init__.py" ];
      };

      rust = mkLanguage {
        symbol = " ";
        style  = "red";
        extensions = [ "rs" ];
        files      = [ "Cargo.toml" "Cargo.lock" ];
      };

      golang = mkLanguage {
        symbol = " ";
        style  = "sapphire";
        extensions = [ "go" ];
        files      = [ "go.mod" "go.sum" "go.work" ];
        folders    = [ "Godeps" ];
      };

      nodejs = mkLanguage {
        symbol = " ";
        style  = "green";
        extensions = [ "js" "mjs" "cjs" "ts" "mts" "cts" ];
        files      = [ "package.json" ".node-version" ".nvmrc" ];
        folders    = [ "node_modules" ];
      };

      # ========================================================================
      # Heavy languages (disabled in FAST)
      # ========================================================================
      java = (mkLanguage {
        symbol = " ";
        style  = "red";
        extensions = [ "java" "class" "jar" ];
        files      = [ "pom.xml" "build.gradle.kts" "build.sbt" ".java-version" ];
      }) // { disabled = fastMode; };

      ruby = (mkLanguage {
        symbol = " ";
        style  = "red";
        extensions = [ "rb" ];
        files      = [ "Gemfile" ".ruby-version" ];
      }) // { disabled = fastMode; };

      php = (mkLanguage {
        symbol = "🐘 ";
        style  = "purple";
        extensions = [ "php" ];
        files      = [ "composer.json" ".php-version" ];
      }) // { disabled = fastMode; };

      lua = (mkLanguage {
        symbol = "🌙 ";
        style  = "blue";
        extensions = [ "lua" ];
        files      = [ ".lua-version" ];
        folders    = [ "lua" ];
      }) // { disabled = fastMode; };

      haskell = (mkLanguage {
        symbol = "λ ";
        style  = "purple";
        extensions = [ "hs" "hs-boot" "cabal" ];
        files      = [ "stack.yaml" "cabal.project" ];
      }) // { disabled = fastMode; };

      elixir = (mkLanguage {
        symbol = "💧 ";
        style  = "purple";
        extensions = [ "ex" "exs" ];
        files      = [ "mix.exs" ];
      }) // { disabled = fastMode; };

      zig = (mkLanguage {
        symbol = "⚡ ";
        style  = "yellow";
        extensions = [ "zig" ];
      }) // { disabled = fastMode; };

      c = {
        format            = "[$symbol$version(-$name)]($style) ";
        symbol            = "C ";
        style             = "bold blue";
        detect_extensions = [ "c" "h" ];
        commands          = [ [ "cc" "--version" ] [ "gcc" "--version" ] [ "clang" "--version" ] ];
        disabled          = fastMode;
      };

      # ========================================================================
      # Nix shell
      # ========================================================================
      nix_shell = {
        format      = "[$symbol$state( \\($name\\))]($style) ";
        symbol      = "❄ ";
        style       = "bold blue";
        impure_msg  = "impure";
        pure_msg    = "pure";
        unknown_msg = "unknown";
        heuristic   = true;
      };

      # ========================================================================
      # Infra & package managers (disabled in FAST)
      # ========================================================================
      docker_context = {
        format          = "[$symbol$context]($style) ";
        symbol          = " ";
        style           = "blue";
        only_with_files = true;
        detect_files    = [ "docker-compose.yml" "docker-compose.yaml" "Dockerfile" ];
        disabled        = !enableInfraTools;
      };

      terraform = {
        format            = "[$symbol$workspace]($style) ";
        symbol            = "💠 ";
        style             = "purple";
        detect_extensions = [ "tf" "tfplan" "tfstate" ];
        detect_folders    = [ ".terraform" ];
        disabled          = !enableInfraTools;
      };

      aws = {
        format   = "[$symbol($profile )(\\($region\\) )(\\[$duration\\])]($style) ";
        symbol   = "☁️ ";
        style    = "yellow";
        disabled = !enableInfraTools;
      };

      package = {
        format          = "[$symbol$version]($style) ";
        symbol          = "📦 ";
        style           = "bold 208";
        display_private = false;
        disabled        = !enableInfraTools;
      };

      conda = {
        format            = "[$symbol$environment]($style) ";
        symbol            = "🅒 ";
        style             = "green";
        ignore_base       = true;
        truncation_length = 1;
        disabled          = !enableInfraTools;
      };

      # ========================================================================
      # System & UX
      # ========================================================================
      cmd_duration = {
        format            = "[$duration]($style) ";
        style             = "yellow";
        min_time          = 3000;     # only show if > 3s
        show_milliseconds = false;
      };

      jobs = {
        format           = "[$symbol$number]($style) ";
        symbol           = "✦ ";
        style            = "bold blue";
        number_threshold = 1;
      };

      battery = {
        format              = "[$symbol$percentage]($style) ";
        full_symbol         = "🔋 ";
        charging_symbol     = "⚡ ";
        discharging_symbol  = "💀 ";
        unknown_symbol      = "❓ ";
        empty_symbol        = "🪫 ";
        display = [
          { threshold = 10; style = "bold red"; }
          { threshold = 30; style = "bold yellow"; }
        ];
        disabled = !enableBattery;
      };

      status = {
        format                = "[$symbol$status]($style) ";
        symbol                = "✗ ";
        style                 = "bold red";
        recognize_signal_code = true;
        disabled              = fastMode;  # rely on character color in FAST
      };

      # Always-off (keep lean)
      azure.disabled        = true;
      gcloud.disabled       = true;
      kubernetes.disabled   = true;
      memory_usage.disabled = true;
      time.disabled         = true;
      sudo.disabled         = true;

      # Light but handy
      direnv = {
        format       = "[$symbol$loaded]($style) ";
        symbol       = "direnv ";
        style        = "bold orange";
        detect_files = [ ".envrc" ];
        disabled     = false;
      };
    };
  };

  # ============================================================================
  # Diagnostics / Quick helpers (FAST only)
  # ============================================================================
  home.shellAliases = lib.mkIf fastMode {
    starship-profile = "echo '🚀 Starship FAST Mode Active'";
    starship-debug   = "STARSHIP_LOG=debug starship module all";
    starfull         = "export STARSHIP_MODE=full; exec zsh -l";
  };
}
