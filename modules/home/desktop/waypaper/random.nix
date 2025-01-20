# Random Wallpaper Service
systemd.user.services.random-wallpaper = {
  Unit = {
    Description = "Change wallpaper randomly";
    PartOf = ["graphical-session.target"];
    After = ["graphical-session.target"];
  };

  Service = {
    Type = "oneshot";
    ExecStart = "/etc/profiles/per-user/kenan/bin/random-wallpaper";
  };
};

# Timer ayarı
systemd.user.timers.random-wallpaper = {
  Unit = {
    Description = "Timer for random wallpaper change";
  };

  Timer = {
    OnBootSec = "1m";
    OnUnitActiveSec = "3m";
  };

  Install = {
    WantedBy = ["timers.target"];
  };
};

