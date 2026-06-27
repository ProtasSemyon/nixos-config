{ pkgs, ... }:

{
  home.pointerCursor = {
    name = "volantes_light_cursors";
    size = 24;
    package = pkgs.volantes-cursors;

    enable = true;

    x11.enable = true;
    gtk.enable = true;
    hyprcursor.enable = true;
    sway.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Orchis-Dark";
      package = pkgs.orchis-theme;
    };
    iconTheme.name = "Papirus-Dark";
    iconTheme.package = pkgs.catppuccin-papirus-folders.override {
      flavor = "macchiato";
      accent = "sapphire";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };
}
