# modules/home/search/default.nix
# ==============================================================================
# Global Search Configuration
# ==============================================================================
# Configures system-wide search utilities and integrations.
# - Integrates with nix-search-tv for Nix package and option search.
#
# ==============================================================================

{ inputs, config, lib, pkgs, ... }:
let
  cfg = config.my.user.search;
  homeDir = config.home.homeDirectory;

  dsearchPkgs = inputs.dsearch.packages.${pkgs.stdenv.hostPlatform.system};
  tomlFormat = pkgs.formats.toml { };

  # Upstream dsearch HM modülü pkgs.system kullanıyor; uyarıyı kesmek için yerel modül.
  dsearchModule = { config, lib, pkgs, ... }:
    let
      dcfg = config.programs.dsearch;
    in {
      options.programs.dsearch = {
        enable = lib.mkEnableOption "danksearch";
        package = lib.mkPackageOption dsearchPkgs "dsearch" { };

        config = lib.mkOption {
          type = lib.types.nullOr tomlFormat.type;
          default = null;
          description = "dsearch configuration (TOML).";
        };
      };

      config = lib.mkIf dcfg.enable {
        home.packages = [ dcfg.package ];

        systemd.user.services.dsearch = {
          Unit = {
            Description = "dsearch - Fast filesystem search service";
            Documentation = "https://github.com/AvengeMedia/dsearch";
            After = [ "network.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${lib.getExe dcfg.package} serve";
            Restart = "on-failure";
            RestartSec = "5s";
            StandardOutput = "journal";
            StandardError = "journal";
            SyslogIdentifier = "dsearch";
          };

          Install.WantedBy = [ "default.target" ];
        };

        xdg.configFile."danksearch/config.toml" = lib.mkIf (dcfg.config != null) {
          source = tomlFormat.generate "dsearch.config.toml" dcfg.config;
        };
      };
    };

  # Varsayılan dsearch konfigürasyonu; kullanıcı cfg.dsearchConfig ile üzerine yazabilir
  defaultDsearchConfig = {
    index_path = "${homeDir}/.cache/danksearch/index";
    listen_addr = ":43654";
    max_file_bytes = 2097152; # 2MB
    worker_count = 4;
    index_all_files = true;
    auto_reindex = false;
    reindex_interval_hours = 24;

    text_extensions = [
      ".txt" ".md" ".go" ".py" ".js" ".ts"
      ".jsx" ".tsx" ".json" ".yaml" ".yml"
      ".toml" ".html" ".css" ".rs" ".c"
      ".cpp" ".h" ".java" ".rb" ".php" ".sh"
    ];

    index_paths = [
      {
        path = homeDir;
        max_depth = 6;
        exclude_hidden = true;
        exclude_dirs = [
          "node_modules" "__pycache__" "venv" "target" "dist" "build" ".cache"
          ".git" ".direnv" ".nix-defexpr" ".kenp"
        ];
      }
      {
        path = "${homeDir}/repos";
        max_depth = 8;
        exclude_hidden = true;
        exclude_dirs = [
          "node_modules" "venv" "target" ".git" "dist" "build" ".direnv" ".cache"
        ];
      }
      {
        path = "${homeDir}/Documents";
        max_depth = 0; # sınırsız
        exclude_hidden = false;
        exclude_dirs = [ ];
      }
      {
        path = "${homeDir}/.anotes";
        max_depth = 0; # sınırsız
        exclude_hidden = false;
        exclude_dirs = [ ];
      }
    ];
  };
in
{
  # Yerel dsearch modülü (pkgs.system uyarısı olmadan)
  imports = [ dsearchModule ];

  options.my.user.search = {
    enable = lib.mkEnableOption "Search utilities configuration";

    dsearchConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "dsearch yapılandırması (boş bırakılırsa varsayılanı kullanır).";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."television/nix_channels.toml".text = ''
      [[cable_channel]]
      name = "nixpkgs"
      source_command = "nix-search-tv print"
      preview_command = "nix-search-tv preview {}"
    '';

    programs.dsearch = {
      enable = true;
      # Kullanıcı ayarlarıyla birleştirilmiş varsayılan TOML
      config = lib.recursiveUpdate defaultDsearchConfig cfg.dsearchConfig;
    };

    # Belirli dizinlerin var olduğundan emin ol (symlink veya normal dizin)
    home.activation.ensureSearchDirs = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "${homeDir}/repos" "${homeDir}/.anotes" "${homeDir}/Documents"
    '';
  };
}
