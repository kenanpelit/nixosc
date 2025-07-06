# modules/home/desktop/waybar/theme.nix
{ kenp, effects, fonts, spacing }:
{
  custom = {
    font = fonts.main.family;
    font_size = "${toString fonts.sizes."2xl"}px";
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
    opacity = effects.opacity;
    border_radius = "8px";
    indicator_height = "2px";
  };
}
