# modules/home/desktop/swaync/theme.nix
{ kenp, effects, fonts }:
{
  style = ''
    @define-color shadow ${effects.shadow};
    @define-color base ${kenp.base};
    @define-color mantle ${kenp.mantle};
    @define-color crust ${kenp.crust};
    @define-color text ${kenp.text};
    @define-color subtext0 ${kenp.subtext0};
    @define-color subtext1 ${kenp.subtext1};
    @define-color surface0 ${kenp.surface0};
    @define-color surface1 ${kenp.surface1};
    @define-color surface2 ${kenp.surface2};
    @define-color blue ${kenp.blue};
    
    * {
      font-family: "${fonts.notifications.family}";
      background-clip: border-box;
    }

    .floating-notifications {
      background: transparent;
    }

    .notification-row {
      outline: none;
      margin: 10px;
      padding: 0;
    }

    .notification {
      background: @base;
      border: 2px solid @surface1;
      border-radius: 8px;
      margin: 5px;
      box-shadow: 0 0 8px 0 @shadow;
    }

    .notification-content {
      padding: 10px;
      margin: 0;
    }

    .close-button {
      background: @surface0;
      color: @text;
      text-shadow: none;
      padding: 0;
      border-radius: 100%;
      margin-top: 10px;
      margin-right: 10px;
      box-shadow: none;
      border: none;
      min-width: 24px;
      min-height: 24px;
    }

    .notification-default-action {
      margin: 0;
      padding: 0;
      border-radius: 8px;
    }

    .notification-default-action:hover {
      background: @surface0;
    }

    .notification-label {
      color: @text;
    }

    .notification-background {
      background: @base;
    }

    .control-center {
      background: @base;
      border: 2px solid @surface1;
      border-radius: 8px;
      margin: 10px;
      box-shadow: 0 0 8px 0 @shadow;
    }
  '';
}
