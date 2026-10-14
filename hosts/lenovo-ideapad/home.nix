{ pkgs, ... }:
let
  # hyprpaper repaints only half the wallpaper after a layout change; restart
  # it once the new profile is applied.
  reloadWallpaper = "${pkgs.systemd}/bin/systemctl --user restart hyprpaper.service";
in
{
  # Home Manager configuration specific to this machine. Everything that is
  # true of the user rather than of the laptop lives in home/.

  # Startup state of the built-in panel; kanshi takes over on hotplug.
  hyprland.monitors = [
    {
      output = "eDP-1";
      mode = "2880x1800@120";
      position = "auto";
      scale = "auto";
    }
  ];

  services.kanshi.settings = [
    {
      profile.name = "office-workstation";
      profile.exec = [
        reloadWallpaper
        "edp-refresh"
      ];
      profile.outputs = [
        {
          criteria = "Dell Inc. DELL U2412M YPPY0725080S";
          status = "enable";
          mode = "1920x1200@59.95000Hz";
          position = "0,0";
        }
        {
          criteria = "eDP-1";
          status = "enable";
          mode = "2880x1800@120Hz";
          position = "0,1200";
          scale = 2.0;
        }
      ];
    }
    {
      profile.name = "home-workstation";
      profile.exec = [
        reloadWallpaper
        "edp-refresh"
      ];
      profile.outputs = [
        {
          criteria = "eDP-1";
          status = "enable";
          mode = "2880x1800@120Hz";
          position = "0,0";
          scale = 2.0;
        }
        {
          criteria = "Dell Inc. DELL P2418D MY3ND93M0GXT";
          status = "enable";
          mode = "2560x1440@60.00Hz";
          position = "1440,0";
          scale = 1.333333;
        }
      ];
    }
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
          mode = "2880x1800@120Hz";
          position = "0,0";
          scale = 2.0;
        }
      ];
    }
  ];

  # Mesa VA-API driver for the Radeon 680M iGPU.
  home.sessionVariables.LIBVA_DRIVER_NAME = "radeonsi";

  # Not in home/packages.nix because it is fetched straight from the JetBrains
  # CDN rather than a binary cache, which makes it a slow, flaky dependency to
  # drag onto a machine that has no use for it.
  home.packages = [ pkgs.jetbrains-toolbox ];
}
