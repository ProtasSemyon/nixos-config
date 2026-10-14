{ pkgs, ... }:
let
  # hyprpaper repaints only half the wallpaper after a layout change; restart
  # it once the new profile is applied.
  reloadWallpaper = "${pkgs.systemd}/bin/systemctl --user restart hyprpaper.service";
in
{
  hyprland.monitors = [
    {
      output = "eDP-1";
      mode = "1920x1080@60";
      position = "auto";
      scale = "auto";
    }
  ];

  # Only the built-in panel so far. Note that on this chassis the HDMI output is
  # wired to the NVIDIA GPU, so an external display needs reverse PRIME rather
  # than just another kanshi profile — add one once that is actually set up.
  services.kanshi.settings = [
    {
      profile.name = "undocked";
      profile.exec = [
        reloadWallpaper
        "edp-refresh"
      ];
      profile.outputs = [
        {
          criteria = "eDP-1";
          status = "enable";
          mode = "1920x1080@60Hz";
          position = "0,0";
          scale = 1.0;
        }
      ];
    }
  ];

  # Mesa VA-API driver for the Vega 8 iGPU, which drives the panel.
  home.sessionVariables.LIBVA_DRIVER_NAME = "radeonsi";
}
