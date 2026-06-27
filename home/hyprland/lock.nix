{ pkgs, ... }:
let
  # Suspend only when running on battery; never auto-suspend on AC power.
  suspendIfOnBattery = pkgs.writeShellScript "suspend-if-on-battery" ''
    if [ "$(cat /sys/class/power_supply/ACAD/online 2>/dev/null)" != "1" ]; then
      ${pkgs.systemd}/bin/systemctl suspend
    fi
  '';
in
{
  # Screen locker (Hyprland ecosystem).
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        grace = 2; # seconds after wake during which a keypress dismisses the lock
      };

      background = [
        {
          monitor = "";
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          font_size = 64;
          font_family = "FiraCode Nerd Font Mono";
          color = "rgb(f8f8f2)";
          position = "0, 120";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "260, 50";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.3;
          outer_color = "rgba(2FBF71cc)";
          inner_color = "rgba(20202088)";
          font_color = "rgb(f8f8f2)";
          fade_on_empty = false;
          placeholder_text = "<i>Password...</i>";
          position = "0, -50";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  # Idle daemon: lock, blank the screen, then suspend.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 300; # 5 min → lock
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 360; # 6 min → screen off
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 900; # 15 min → suspend (battery only)
          on-timeout = "${suspendIfOnBattery}";
        }
      ];
    };
  };
}
