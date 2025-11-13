{
  pkgs,
  inputs,
  system,
  ...
}:
let
  hyprpaper = ./hyprpaper;
in
{
  imports = [
    hyprpaper
  ];

  hyprpaper = {
    enable = true;
    wallpaper = "MagicForest.png";
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";
    extraPackages = with pkgs.kdePackages; [
      qt5compat
      qtdeclarative
      qtsvg
      qtmultimedia
    ];
  };

  programs.hyprland.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    HYPRSHOT_DIR = "$HOME/Pictures/Screenshots";
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  xdg.portal.enable = true;

  home-manager.users.smn = {
    services.hyprpolkitagent.enable = true;
    services.dunst.enable = true;
    services.gammastep = {
      enable = true;

      dawnTime = "6:00-7:45";
      duskTime = "18:35-20:15";

      temperature = {
        day = 5500;
        night = 3400;
      };
    };

    services.blueman-applet.enable = true;
    programs.rofi.enable = true;

    xdg.portal.extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];

    home.packages = with pkgs; [
      qimgv
      hyprsunset
      hyprshot
      hyprcursor
      pavucontrol
      networkmanagerapplet
      cliphist
      brightnessctl

      wl-clipboard-rs
      dmenu

      libnotify

      inputs.hyprland-guiutils.packages."${system}".default
    ];

    wayland.windowManager.hyprland = {
      enable = true;

      package = null;
      portalPackage = null;

      settings = {
        "$mainMod" = "SUPER";
        "$shiftMod" = "SHIFT";
        "$terminal" = "foot";
        "$fileManager" = "thunar";
        "$menu" = "rofi -show drun -show-icons";

        input = {
          kb_layout = "us,ru";
          kb_options = "grp:caps_toggle,grp_led:caps";
          touchpad = {
            natural_scroll = true;
          };
        };

        gesture = [
          "3, horizontal, workspace"
          "3, vertical, mod: ALT, close"
          "4, vertical, fullscreen"
          "3, vertical, special, magic"
        ];

        monitor = [
          "eDP-1, 2880x1800@120, auto, auto, vrr, 1"
        ];

        general = {
          gaps_in = 5;
          gaps_out = 2;

          resize_on_border = true;
          layout = "dwindle";

          "col.active_border" = "rgba(2FBF71cc) rgba(75D6FFcc) 90deg";
          "col.inactive_border" = "rgba(1C3A2Baa)";

          "col.nogroup_border" = "rgba(10281Fcc)";
          "col.nogroup_border_active" = "rgba(75D6FFaa) rgba(2FBF71aa) 90deg";

          no_border_on_floating = false;
          border_size = 1;
        };

        decoration = {
          rounding = 5;
          active_opacity = 1.0;
          inactive_opacity = 0.93;
          fullscreen_opacity = 1.0;

          shadow = {
            enabled = true;
          };
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        misc = {
          vfr = false;
          vrr = 0;
          force_default_wallpaper = -1;
          disable_hyprland_logo = true;
        };

        master = {
          new_status = "master";
        };

        animations = {
          enabled = "yes, please :)";

          bezier = [
            "easeOutQuint,0.23,1,0.32,1"
            "easeInOutCubic,0.65,0.05,0.36,1"
            "linear,0,0,1,1"
            "almostLinear,0.5,0.5,0.75,1.0"
            "quick,0.15,0,0.1,1"
          ];

          animation = [
            "global, 1, 5, default"
            "border, 1, 2.5, easeOutQuint"
            "windows, 1, 2.4, easeOutQuint"
            "windowsIn, 1, 2, easeOutQuint, popin 87%"
            "windowsOut, 1, 0.75, linear, popin 87%"
            "fadeIn, 1, 0.9, almostLinear"
            "fadeOut, 1, 0.8, almostLinear"
            "fade, 1, 1.5, quick"
            "layers, 1, 1.9, easeOutQuint"
            "layersIn, 1, 2, easeOutQuint, fade"
            "layersOut, 1, 0.75, linear, fade"
            "fadeLayersIn, 1, 0.9, almostLinear"
            "fadeLayersOut, 1, 0.7, almostLinear"
            "workspaces, 1, 1, almostLinear, fade"
            "workspacesIn, 1, 0.6, almostLinear, fade"
            "workspacesOut, 1, 1, almostLinear, fade"
          ];
        };

        bind = [
          "$mainMod, RETURN, exec, $terminal"
          "$mainMod, C, killactive,"
          "$mainMod, M, exit,"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, V, togglefloating,"
          "$mainMod, R, exec, $menu"
          "$mainMod, P, pseudo," # dwindle
          "$mainMod, J, togglesplit," # dwindle

          # Move focus with mainMod + arrow keys
          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"

          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"

          "$mainMod, A, togglespecialworkspace, cookies"
          "$mainMod SHIFT, A, movetoworkspace, special:cookies"

          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"

          "$mainMod, P, exec, hyprshot -zm window"
          "ALT, P, exec, hyprshot -zm region"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (
            builtins.genList (
              i:
              let
                ws = i + 1;
              in
              [
                "$mainMod, code:1${toString i}, workspace, ${toString ws}"
                "$mainMod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            ) 9
          )
        );

        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        bindel = [
          ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ",XF86MonBrightnessUp, exec, brightnessctl s 10%+"
          ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"
        ];

        bindl = [
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
        ];

        windowrulev2 = [
          #Blueman
          "float, class:^(\.blueman.*)$"
          "move 65% 5%, class:^(\.blueman.*)$"
          "size <500 200, class:^(\.blueman.*)$"

          #YandexMusic
          "float, class:^(yandex-music)$"
          "size 65% 65%, class:^(yandex-music)$"

          "suppressevent maximize, class:.*"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

          "bordercolor rgb(ff5555),xwayland:1"

          #Foot opacity
          "opacity 0.93,class:^(foot)$"

          #Android build
          "float, class:^(com\.example\..+)$"
        ];

        exec-once = [
          "waybar"
          "nm-applet --indicator"
          "[workspace 1 silent] firefox"
          "[workspace special:magic silent] Telegram"
          "[workspace special:magic silent] yandex-music"
        ];

        group = {
          groupbar = {
            "col.active" = "rgba(2FBF71bb) rgba(75D6FFbb) 90deg";
            "col.inactive" = "rgba(10281Fcc)";
          };
        };
      };
    };
  };
}
