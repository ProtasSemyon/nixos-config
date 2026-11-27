{
  config,
  lib,
  pkgs,
  ...
}:
let
  # hyprctl dispatch takes a Lua expression since the Lua config; the old
  # `dispatch dpms off` form is a syntax error now.
  dpms = action: "hyprctl dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";

  # Suspend only when running on battery; never auto-suspend on AC power, and
  # never on a machine that has no battery at all (a desktop). The adapter's
  # name differs between vendors (ACAD, AC0, ...), so match on type instead.
  # Batteries with scope=Device belong to peripherals (a Logitech mouse or
  # keyboard shows up as hidpp_battery_*) and say nothing about the machine.
  suspendIfOnBattery = pkgs.writeShellScript "suspend-if-on-battery" ''
    battery=0
    for d in /sys/class/power_supply/*; do
      case "$(cat "$d/type" 2>/dev/null)" in
        Battery) [ "$(cat "$d/scope" 2>/dev/null)" = "Device" ] || battery=1 ;;
        Mains) [ "$(cat "$d/online" 2>/dev/null)" = "1" ] && exit 0 ;;
      esac
    done
    [ "$battery" = "1" ] && exec ${pkgs.systemd}/bin/systemctl suspend
    exit 0
  '';
in
{
  options.hyprland.idleSuspend = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Whether hypridle suspends the machine after 15 minutes idle (on battery
      only). Hosts that must stay reachable set this to false; locking and
      blanking the screen are unaffected.
    '';
  };

  # Screen locker (Hyprland ecosystem).
  config.programs.hyprlock = {
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

  # Idle daemon: lock, blank the screen, then (where allowed) suspend.
  config.services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = dpms "on";
      };

      listener = [
        {
          timeout = 300; # 5 min → lock
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 360; # 6 min → screen off
          on-timeout = dpms "off";
          on-resume = dpms "on";
        }
      ]
      ++ lib.optional config.hyprland.idleSuspend {
        timeout = 900; # 15 min → suspend (battery only)
        on-timeout = "${suspendIfOnBattery}";
      };
    };
  };
}
