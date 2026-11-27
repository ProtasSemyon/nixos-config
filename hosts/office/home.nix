{ pkgs, ... }:
let
  # hyprpaper repaints only half the wallpaper after a layout change; restart
  # it once the new profile is applied.
  reloadWallpaper = "${pkgs.systemd}/bin/systemctl --user restart hyprpaper.service";
in
{
  # Dell U2412M on the iGPU's DisplayPort (EDID read on the machine: native
  # 1920x1200 @ 59.95 Hz). No built-in panel, so host.display.internal stays
  # unset and edp-refresh is a no-op.
  hyprland.monitors = [
    {
      output = "DP-2";
      mode = "1920x1200@60";
      position = "auto";
      scale = "1";
    }
  ];

  services.kanshi.settings = [
    {
      profile.name = "desk";
      profile.exec = [ reloadWallpaper ];
      profile.outputs = [
        {
          criteria = "Dell Inc. DELL U2412M YPPY084R0LES";
          status = "enable";
          mode = "1920x1200@59.95000Hz";
          position = "0,0";
        }
      ];
    }
  ];

  # Mostly a server: lock and blank the screen when idle, never suspend.
  # (sleep.conf in ./default.nix forbids it system-wide as well.)
  hyprland.idleSuspend = false;

  # UHD 630 (Coffee Lake): VA-API through intel-media-driver, which
  # nixos-hardware's common-gpu-intel installs.
  home.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
}
