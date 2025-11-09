# modules/home/starship/default.nix
# ==============================================================================
# Starship Prompt - Catppuccin Mocha + Pure Theme Style (Full Featured)
# Author: Kenan Pelit
# Description: Minimal, fast prompt with Catppuccin colors - ALL FEATURES
# ==============================================================================
{ config, lib, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    
    settings = {
      # ========================================================================
      # Performance & Format
      # ========================================================================
      command_timeout = 1000;
      scan_timeout = 30;
      add_newline = true;
      
      # Minimal format like Pure theme
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$git_state"
        "$python"
        "$rust"
        "$golang"
        "$nodejs"
        "$java"
        "$c"
        "$ruby"
        "$php"
        "$lua"
        "$haskell"
        "$elixir"
        "$zig"
        "$nix_shell"
        "$docker_context"
        "$terraform"
        "$aws"
        "$package"
        "$conda"
        "$cmd_duration"
        "$line_break"
        "$jobs"
        "$battery"
        "$status"
        "$character"
      ];
      
      # ========================================================================
      # Catppuccin Mocha Colors
      # ========================================================================
      palette = "catppuccin_mocha";
      
      palettes.catppuccin_mocha = {
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        mauve = "#cba6f7";
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
        text = "#cdd6f4";
        subtext1 = "#bac2de";
        subtext0 = "#a6adc8";
        overlay2 = "#9399b2";
        overlay1 = "#7f849c";
        overlay0 = "#6c7086";
        surface2 = "#585b70";
        surface1 = "#45475a";
        surface0 = "#313244";
        base = "#1e1e2e";
        mantle = "#181825";
        crust = "#11111b";
      };

      # ========================================================================
      # Character (Catppuccin Mauve Theme)
      # ========================================================================
      character = {
        success_symbol = "[❯](bold mauve)";           # Normal: mor
        error_symbol = "[❯](bold red)";               # Error: kırmızı
        vimcmd_symbol = "[❮](bold lavender)";         # Vim normal: açık mor
        vimcmd_visual_symbol = "[❮](bold pink)";      # Vim visual: pembe
        vimcmd_replace_symbol = "[❮](bold mauve)";    # Vim replace: mor
      };
      
      # ========================================================================
      # Username (only show on SSH or root)
      # ========================================================================
      username = {
        format = "[$user]($style) ";
        style_user = "bold sapphire";
        style_root = "bold red";
        show_always = false;
        disabled = false;
      };
      
      # ========================================================================
      # Hostname (SSH only)
      # ========================================================================
      hostname = {
        ssh_only = true;
        ssh_symbol = "🌐 ";
        format = "[@$hostname]($style) ";
        style = "bold blue";
        disabled = false;
      };
      
      # ========================================================================
      # Directory (Pure style - minimal)
      # ========================================================================
      directory = {
        format = "[$path]($style) ";
        style = "bold sapphire";
        truncation_length = 3;
        truncation_symbol = "…/";
        truncate_to_repo = true;
        read_only = " 🔒";
        read_only_style = "red";
        
        # Unicode Emoji iconlar - her terminalde çalışır
        substitutions = {
          "Documents" = "📄 Docs";
          "Downloads" = "📥 DL";
          "Music" = "🎵 Music";
          "Pictures" = "🖼️ Pics";
          "Videos" = "🎬 Videos";
          "Projects" = "💼 Proj";
          "Desktop" = "🖥️ Desktop";
          ".config" = "⚙️ cfg";
          ".nixosc" = "❄️ nixosc";
        };
      };
 
      # ========================================================================
      # Git Branch (Pure style with Catppuccin colors)
      # ========================================================================
      git_branch = {
        format = "[$symbol$branch]($style) ";
        symbol = "⎇ ";
        style = "bold mauve";
        truncation_length = 20;
        truncation_symbol = "…";
      };
      
      # ========================================================================
      # Git Status (concise, colorful)
      # ========================================================================
      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        style = "bold red";
        
        # Catppuccin-friendly symbols
        ahead = "⇡$count";
        behind = "⇣$count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
        
        # Minimal symbols
        conflicted = "=";
        deleted = "✘";
        renamed = "»";
        modified = "!";
        staged = "+";
        untracked = "?";
        stashed = "$";
      };
      
      # ========================================================================
      # Git State
      # ========================================================================
      git_state = {
        format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
        style = "bold yellow";
      };
      
      # ========================================================================
      # Languages (minimal, only when in project)
      # ========================================================================
      
      # Python
      python = {
        format = "[$symbol$version]($style) ";
        symbol = "🐍 ";
        style = "yellow";
        detect_extensions = ["py"];
        detect_files = [
          "requirements.txt"
          ".python-version"
          "pyproject.toml"
          "Pipfile"
          "tox.ini"
          "setup.py"
          "__init__.py"
        ];
      };
      
      # Rust
      rust = {
        format = "[$symbol$version]($style) ";
        symbol = "🦀 ";
        style = "red";
        detect_extensions = ["rs"];
        detect_files = ["Cargo.toml" "Cargo.lock"];
      };
      
      # Go
      golang = {
        format = "[$symbol$version]($style) ";
        symbol = "🐹 ";
        style = "sapphire";
        detect_extensions = ["go"];
        detect_files = [
          "go.mod"
          "go.sum"
          "go.work"
          "glide.yaml"
          "Gopkg.yml"
          "Gopkg.lock"
          ".go-version"
        ];
        detect_folders = ["Godeps"];
      };
      
      # Node.js
      nodejs = {
        format = "[$symbol$version]($style) ";
        symbol = "⬢ ";
        style = "green";
        detect_extensions = ["js" "mjs" "cjs" "ts" "mts" "cts"];
        detect_files = ["package.json" ".node-version" ".nvmrc"];
        detect_folders = ["node_modules"];
      };
      
      # Java
      java = {
        format = "[$symbol$version]($style) ";
        symbol = "☕ ";
        style = "red";
        detect_extensions = ["java" "class" "jar" "gradle" "clj" "cljc"];
        detect_files = [
          "pom.xml"
          "build.gradle.kts"
          "build.sbt"
          ".java-version"
          "deps.edn"
          "project.clj"
          "build.boot"
          ".sdkmanrc"
        ];
      };
      
      # C/C++
      c = {
        format = "[$symbol$version(-$name)]($style) ";
        symbol = "C ";
        style = "bold blue";
        detect_extensions = ["c" "h"];
        commands = [
          ["cc" "--version"]
          ["gcc" "--version"]
          ["clang" "--version"]
        ];
      };
      
      # Ruby
      ruby = {
        format = "[$symbol$version]($style) ";
        symbol = "💎 ";
        style = "red";
        detect_extensions = ["rb"];
        detect_files = ["Gemfile" ".ruby-version"];
        detect_variables = ["RUBY_VERSION" "RBENV_VERSION"];
      };
      
      # PHP
      php = {
        format = "[$symbol$version]($style) ";
        symbol = "🐘 ";
        style = "purple";
        detect_extensions = ["php"];
        detect_files = ["composer.json" ".php-version"];
      };
      
      # Lua
      lua = {
        format = "[$symbol$version]($style) ";
        symbol = "🌙 ";
        style = "blue";
        lua_binary = "lua";
        detect_extensions = ["lua"];
        detect_files = [".lua-version"];
        detect_folders = ["lua"];
      };
      
      # Haskell
      haskell = {
        format = "[$symbol$version]($style) ";
        symbol = "λ ";
        style = "purple";
        detect_extensions = ["hs" "cabal" "hs-boot"];
        detect_files = ["stack.yaml" "cabal.project"];
      };
      
      # Elixir
      elixir = {
        format = "[$symbol$version \\(OTP $otp_version\\)]($style) ";
        symbol = "💧 ";
        style = "purple";
        detect_files = ["mix.exs"];
      };
      
      # Zig
      zig = {
        format = "[$symbol$version]($style) ";
        symbol = "⚡ ";
        style = "yellow";
        detect_extensions = ["zig"];
      };
      
      # ========================================================================
      # Nix Shell (important for NixOS)
      # ========================================================================
      nix_shell = {
        format = "[$symbol$state( \\($name\\))]($style) ";
        symbol = "❄️  ";
        style = "bold blue";
        impure_msg = "[impure](bold red)";
        pure_msg = "[pure](bold green)";
        unknown_msg = "[unknown](bold yellow)";
        heuristic = true;
      };
      
      # ========================================================================
      # Tools & Frameworks
      # ========================================================================
      
      # Docker
      docker_context = {
        format = "[$symbol$context]($style) ";
        symbol = "🐳 ";
        style = "blue";
        only_with_files = true;
        detect_files = [
          "docker-compose.yml"
          "docker-compose.yaml"
          "Dockerfile"
        ];
        disabled = false;
      };
      
      # Terraform
      terraform = {
        format = "[$symbol$workspace]($style) ";
        symbol = "💠 ";
        style = "purple";
        detect_extensions = ["tf" "tfplan" "tfstate"];
        detect_folders = [".terraform"];
        disabled = false;
      };
      
      # AWS
      aws = {
        format = "[$symbol($profile )(\\($region\\) )(\\[$duration\\])]($style) ";
        symbol = "☁️  ";
        style = "yellow";
        disabled = false;
      };
      
      # Package Version
      package = {
        format = "[$symbol$version]($style) ";
        symbol = "📦 ";
        style = "bold 208";
        display_private = false;
        disabled = false;
      };
      
      # Conda Environment
      conda = {
        format = "[$symbol$environment]($style) ";
        symbol = "🅒 ";
        style = "green";
        ignore_base = true;
        truncation_length = 1;
        disabled = false;
      };
      
      # ========================================================================
      # System Information
      # ========================================================================
      
      # Command Duration (Pure style - minimal)
      cmd_duration = {
        format = "[⏱ $duration]($style) ";
        style = "yellow";
        min_time = 2000;
        show_milliseconds = false;
      };
      
      # Jobs
      jobs = {
        format = "[$symbol$number]($style) ";
        symbol = "✦ ";
        style = "bold blue";
        number_threshold = 1;
        symbol_threshold = 1;
      };
      
      # Battery (laptop için)
      battery = {
        format = "[$symbol$percentage]($style) ";
        full_symbol = "🔋 ";
        charging_symbol = "⚡ ";
        discharging_symbol = "💀 ";
        unknown_symbol = "❓ ";
        empty_symbol = "🪫 ";
        disabled = false;
        
        display = [
          {
            threshold = 10;
            style = "bold red";
          }
          {
            threshold = 30;
            style = "bold yellow";
          }
        ];
      };
      
      # Status
      status = {
        format = "[$symbol$status]($style) ";
        symbol = "✖ ";
        style = "bold red";
        disabled = false;
        recognize_signal_code = true;
      };
      
      # ========================================================================
      # Sudo indicator (wizard emoji) - İSTERSENİZ KAPATIN
      # ========================================================================
      sudo = {
        format = "[as $symbol]($style) ";
        symbol = "🧙";
        style = "bold red";
        disabled = true;  # "as 🧙" istemiyorsanız true yapın
      };
      
      # ========================================================================
      # Additional Tools (disabled by default, enable if needed)
      # ========================================================================
      gcloud.disabled = true;
      kubernetes.disabled = true;
      memory_usage.disabled = true;
      time.disabled = true;
      shell.disabled = true;
      os.disabled = true;
      container.disabled = true;
      direnv = {
        format = "[$symbol$loaded/$allowed]($style) ";
        symbol = "direnv ";
        style = "bold orange";
        disabled = false;
        detect_files = [".envrc"];
        allowed_msg = "allowed";
        not_allowed_msg = "not allowed";
        denied_msg = "denied";
        loaded_msg = "loaded";
        unloaded_msg = "not loaded";
      };
    };
  };
}

