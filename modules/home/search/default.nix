# modules/home/search/default.nix
# ==============================================================================
# Home Manager module for search.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
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
  # Tüm ev dizini için tek indeks; Downloads ve .kenp hariç, diğer yaygın çöp klasörleri de dışarıda
  defaultIndexPaths = [
    {
      path = homeDir;
      max_depth = 0; # sınırsız
      exclude_hidden = false; # gizliler de taransın (.config, .anotes vs.)
      exclude_dirs = [
        # İstenen hariç tutulanlar
        "Downloads"
        ".kenp"
        # Gürültü/çöp klasörleri
        ".cache" ".direnv" ".nix-defexpr" ".git" ".venv" "venv"
        "node_modules" "dist" "build" "target" "__pycache__"
      ];
    }
  ];

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

    # Tek path: HOME (Downloads ve .kenp hariç)
    index_paths = defaultIndexPaths;
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
  };
}
