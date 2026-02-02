# modules/home/starship/default.nix
# ==============================================================================
# Home module for Starship prompt configuration.
# Installs starship and writes prompt settings via Home Manager.
# Keep prompt tweaks here instead of editing starship.toml manually.
# ==============================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.my.user.starship;
  toml = pkgs.formats.toml { };

  # ----------------------------------------------------------------------------
  # Catppuccin Mocha Palette
  # ----------------------------------------------------------------------------
  catppuccinPalette = {
    rosewater="#f5e0dc"; flamingo="#f2cdcd"; pink="#f5c2e7"; mauve="#cba6f7";
    red="#f38ba8"; maroon="#eba0ac"; peach="#fab387"; yellow="#f9e2af";
    green="#a6e3a1"; teal="#94e2d5"; sky="#89dceb"; sapphire="#74c7ec";
    blue="#89b4fa"; lavender="#b4befe"; text="#cdd6f4"; subtext1="#bac2de";
    subtext0="#a6adc8"; overlay2="#9399b2"; overlay1="#7f849c"; overlay0="#6c7086";
    surface2="#585b70"; surface1="#45475a"; surface0="#313244"; base="#1e1e2e";
    mantle="#181825"; crust="#11111b";
  };

  mkLanguage = { symbol, style, extensions, files ? [], folders ? [] }: {
    format            = "[$symbol$version]($style) ";
    inherit symbol style;
    detect_extensions = extensions;
    detect_files      = files;
    detect_folders    = folders;
  };

  mkSettings = mode:
    let
      fastMode = mode == "fast";

      # Conservative timeouts: avoid "timed out" blanks on slow/remote FS
      commandTimeout = if fastMode then 150 else 300; # ms
      # `scan_timeout` controls how long Starship is allowed to scan the current
      # directory for detect_* heuristics. Too low -> log spam like:
      #   "Scanning current directory timed out"
      scanTimeout    = if fastMode then 120 else 300;  # ms

      # Feature toggles
      enableGitState       = !fastMode; # rebase/merge state is expensive
      enableGitMetrics     = !fastMode; # added/removed counters (heavy-ish)
      enableInfraTools     = !fastMode; # Docker/Terraform/AWS/Package/Conda
      enableBattery        = !fastMode; # battery only in FULL
      enableClock          = !fastMode; # clock only in FULL

      # ----------------------------------------------------------------------------
      # Layouts
      # - Use $fill to create a right-aligned area (right prompt feeling)
      # ----------------------------------------------------------------------------
      fastLeft = lib.concatStrings [
        "$username$hostname$directory"
        "$git_branch$git_status"
        "$python$rust$golang$nodejs"
        "$nix_shell"
      ];

      fullLeft = lib.concatStrings [
        "$username$hostname$directory"
        "$git_branch$git_status$git_state"
        "$python$rust$golang$nodejs$java$c$ruby$php$lua$haskell$elixir$zig"
        "$nix_shell"
        "$docker_context$terraform$aws$package$conda"
      ];

      fastRight = lib.concatStrings [ "$cmd_duration" ];
      fullRight = lib.concatStrings [ "$cmd_duration$time$battery$status" ];

      baseFormat = left: right:
        # 2 lines: line-1 (left … fill … right) + line-2 (jobs + prompt char)
        lib.concatStrings [ left "$fill" right "$line_break" "$jobs$character" ];

      format =
        if fastMode then baseFormat fastLeft fastRight else baseFormat fullLeft fullRight;

      # ----------------------------------------------------------------------------
      # DRY helpers
      # ----------------------------------------------------------------------------
      gitConfig = {
        branch = {
          # Keep short, add a trailing space to avoid token sticking
          format             = "[$symbol$branch]($style) ";
          symbol             = " "; # Nerd: git-branch
          style              = "bold mauve";
          truncation_length  = 15;
          truncation_symbol  = "…";
        };

        status = {
          # $all_status includes staged/modified/untracked/etc
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
          stashed           = "\\$";
          ignore_submodules = true; # major win on mono-repos
        };

        state = {
          format   = "[$state( $progress_current/$progress_total)]($style) ";
          style    = "bold yellow";
          disabled = !enableGitState;
        };

        metrics = {
          format             = "([+$added]([-]$deleted)) ";
          disabled           = !enableGitMetrics;
          added_style        = "green";
          deleted_style      = "red";
          only_nonzero_diffs = true;
        };
      };
    in
    {
      # ========================================================================
      # Core performance
      # ========================================================================
      palette = "catppuccin_mocha";
      palettes.catppuccin_mocha = catppuccinPalette;

      command_timeout = commandTimeout;
      scan_timeout    = scanTimeout;

      # We already render a 2-line prompt via `$line_break`. An extra blank line
      # between prompts looks nice, but costs vertical space and makes the UI
      # feel "slower" when iterating quickly.
      add_newline     = false;

      # Main layout (left … fill … right)
      format       = format;
      right_format = "";

      # ========================================================================
      # Prompt atoms
      # ========================================================================
      fill.symbol = " ";

      character = {
        success_symbol        = "[❯](bold mauve)";
        error_symbol          = "[❯](bold red)";
        vimcmd_symbol         = "[❮](bold lavender)";
        vimcmd_visual_symbol  = "[❮](bold pink)";
        vimcmd_replace_symbol = "[❮](bold mauve)";
      };

      username = {
        format      = "[$user]($style) ";
        show_always = false; # show on SSH or root only
        style_user  = "bold sapphire";
        style_root  = "bold red";
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
        truncation_length = 3;
        truncation_symbol = "…/";
        truncate_to_repo  = true;
        read_only         = " ";
        read_only_style   = "red";
        substitutions = {
          "Documents" = " ";
          "Downloads" = " ";
          "Music"     = " ";
          "Pictures"  = " ";
          "Videos"    = " ";
          "Projects"  = " ";
          "Desktop"   = " ";
          ".config"   = " ";
          ".nixosc"   = " ";
        };
      };

      # ========================================================================
      # Git (latency hotspot) — keep lean on FAST
      # ========================================================================
      git_branch  = gitConfig.branch;
      git_status  = gitConfig.status;
      git_state   = gitConfig.state;
      git_metrics = gitConfig.metrics;

      # ========================================================================
      # Core languages
      # ========================================================================
      # NOTE: For speed we avoid `detect_extensions` for "popular" languages.
      # A single stray `.py`/`.js` file in a large repo would trigger version
      # checks on every prompt draw. We only enable them when we see a real
      # project marker (pyproject/Cargo/go.mod/package.json, etc).
      python = mkLanguage {
        symbol = " ";
        style  = "yellow";
        extensions = [ ];
        files      = [ "requirements.txt" "pyproject.toml" "Pipfile" ".python-version" "tox.ini" "setup.py" ];
        folders    = [ ".venv" "venv" ];
      };

      rust = mkLanguage {
        symbol = " ";
        style  = "red";
        extensions = [ ];
        files      = [ "Cargo.toml" "Cargo.lock" ];
      };

      golang = mkLanguage {
        symbol = " ";
        style  = "sapphire";
        extensions = [ ];
        files      = [ "go.mod" "go.sum" "go.work" ];
        folders    = [ "Godeps" ];
      };

      nodejs = mkLanguage {
        symbol = " ";
        style  = "green";
        extensions = [ ];
        files      = [ "package.json" "pnpm-lock.yaml" "yarn.lock" "package-lock.json" ".node-version" ".nvmrc" ];
        folders    = [ "node_modules" ];
      };

      # ========================================================================
      # Heavy languages (disabled on FAST)
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
        impure_msg  = "";
        pure_msg    = "";
        unknown_msg = "";
        heuristic   = false;
        disabled    = false;
      };

      # ========================================================================
      # Infra & package managers (disabled on FAST)
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
      # System & UX (right side)
      # ========================================================================
      cmd_duration = {
        format            = "[$duration]($style) ";
        style             = "yellow";
        min_time          = 3000;
        show_milliseconds = false;
      };

      time = {
        format      = "[$time]($style) ";
        style       = "subtext1";
        disabled    = !enableClock;
        time_format = "%H:%M";
        use_12hr    = false;
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
        disabled              = fastMode; # rely on character color on FAST
      };

      jobs = {
        format           = "[$symbol$number]($style) ";
        symbol           = "✦ ";
        style            = "bold blue";
        number_threshold = 1;
      };

      # ========================================================================
      # Always-off to stay lean
      # ========================================================================
      azure.disabled        = true;
      gcloud.disabled       = true;
      kubernetes.disabled   = true;
      memory_usage.disabled = true;
      sudo.disabled         = true;
      direnv = {
        format       = "[$symbol$loaded]($style) ";
        symbol       = "direnv ";
        style        = "bold peach";
        detect_files = [ ".envrc" ];
        disabled     = false;
      };
    };

  fastSettings = mkSettings "fast";
  fullSettings = mkSettings "full";

  fastToml = toml.generate "starship-fast.toml" fastSettings;
  fullToml = toml.generate "starship-full.toml" fullSettings;

in
{
  options.my.user.starship = {
    enable = lib.mkEnableOption "Starship prompt";
    defaultMode = lib.mkOption {
      type = lib.types.enum [ "fast" "full" ];
      default = "fast";
      description = "Default Starship config used for the standard `~/.config/starship.toml`.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;

      # The "default" config file stays deterministic (fast by default), but we
      # also generate a FULL config and provide easy switching via STARSHIP_CONFIG.
      settings = if cfg.defaultMode == "full" then fullSettings else fastSettings;
    };
  
    home.file.".config/starship/starship-fast.toml".source = fastToml;
    home.file.".config/starship/starship-full.toml".source = fullToml;

    # ============================================================================
    # Diagnostics / Quick helpers (FAST only)
    # ============================================================================
    home.shellAliases = {
      starship-profile = ''
        if [[ "''${STARSHIP_CONFIG:-}" == *"/starship-full.toml" ]]; then
          echo "Starship Mode: FULL"
        else
          echo "Starship Mode: FAST"
        fi
      '';
      starship-debug = "STARSHIP_LOG=debug starship module all";
      starship-timings = "starship timings";  # performans analizi
    
      # Mode switching
      starfast = "export STARSHIP_CONFIG=$HOME/.config/starship/starship-fast.toml; exec zsh -l";
      starfull = "export STARSHIP_CONFIG=$HOME/.config/starship/starship-full.toml; exec zsh -l";
    
      # Config testing
      starship-test = "starship print-config";
    };
  };
}
