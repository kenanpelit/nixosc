# modules/home/desktop/waybar/theme.nix
{ kenp, effects, fonts }:
{
  custom = {
    font = fonts.main.family;
    font_size = fonts.main.size;
    font_weight = fonts.main.weight;
    text_color = kenp.text;
    background_0 = kenp.crust;
    background_1 = kenp.base;
    border_color = kenp.surface1;
    red = kenp.red;
    green = kenp.green;
    yellow = kenp.yellow;
    blue = kenp.blue;
    magenta = kenp.mauve;
    cyan = kenp.sky;
    orange = kenp.peach;
    orange_bright = kenp.peach;
    opacity = effects.opacity;
    indicator_height = "2px";
  };
}
