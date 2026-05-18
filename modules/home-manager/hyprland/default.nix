{
  pkgs,
  inputs,
  lib,
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

      inputs.hyprland-guiutils.packages.${stdenv.hostPlatform.system}.default
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      extraConfig = "-- Lua config is handled via xdg.configFile";
    };

    xdg.configFile."hypr/hyprland.lua".text = ''
      local mainMod = "SUPER"
      local terminal = "foot"
      local fileManager = "thunar"
      local menu = "rofi -show drun -show-icons"

      hl.monitor({
          output   = "eDP-1",
          mode     = "2880x1800@120",
          position = "auto",
          scale    = "auto",
      })

      hl.config({
          general = {
              gaps_in  = 5,
              gaps_out = 2,
              border_size = 1,
              col = {
                  active_border   = { colors = {"rgba(2FBF71cc)", "rgba(75D6FFcc)"}, angle = 90 },
                  inactive_border = "rgba(1C3A2Baa)",
              },
              resize_on_border = true,
              layout = "dwindle",
          },
          decoration = {
              rounding = 5,
              active_opacity   = 1.0,
              inactive_opacity = 0.93,
              shadow = {
                  enabled = true,
              },
          },
          dwindle = {
              preserve_split = true,
          },
          misc = {
              force_default_wallpaper = -1,
              disable_hyprland_logo = true,
          },
          master = {
              new_status = "master",
          },
          input = {
              kb_layout  = "us,ru",
              kb_options = "grp:caps_toggle,grp_led:caps",
              follow_mouse = 1,
              touchpad = {
                  natural_scroll = true,
              },
          },
          group = {
              groupbar = {
                  col = {
                      active   = { colors = {"rgba(2FBF71bb)", "rgba(75D6FFbb)"}, angle = 90 },
                      inactive = "rgba(10281Fcc)",
                  },
              },
          },
      })

      hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
      hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
      hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
      hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
      hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

      hl.animation({ leaf = "global",        enabled = true,  speed = 5,    bezier = "default" })
      hl.animation({ leaf = "border",        enabled = true,  speed = 2.5,  bezier = "easeOutQuint" })
      hl.animation({ leaf = "windows",       enabled = true,  speed = 2.4,  bezier = "easeOutQuint" })
      hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 2,    bezier = "easeOutQuint", style = "popin 87%" })
      hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 0.75, bezier = "linear",       style = "popin 87%" })
      hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 0.9,  bezier = "almostLinear" })
      hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 0.8,  bezier = "almostLinear" })
      hl.animation({ leaf = "fade",          enabled = true,  speed = 1.5,  bezier = "quick" })
      hl.animation({ leaf = "layers",        enabled = true,  speed = 1.9,  bezier = "easeOutQuint" })
      hl.animation({ leaf = "layersIn",      enabled = true,  speed = 2,    bezier = "easeOutQuint", style = "fade" })
      hl.animation({ leaf = "layersOut",     enabled = true,  speed = 0.75, bezier = "linear",       style = "fade" })
      hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 0.9,  bezier = "almostLinear" })
      hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 0.7,  bezier = "almostLinear" })
      hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1,    bezier = "almostLinear", style = "fade" })
      hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 0.6,  bezier = "almostLinear", style = "fade" })
      hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1,    bezier = "almostLinear", style = "fade" })

      hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
      hl.gesture({ fingers = 3, direction = "vertical",   mods = "ALT", action = "close" })
      hl.gesture({ fingers = 4, direction = "vertical",   action = "fullscreen" })
      hl.gesture({ fingers = 3, direction = "vertical",   action = "special", workspace_name = "magic" })

      -- Binds
      hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
      hl.bind(mainMod .. " + C",      hl.dsp.window.close())
      hl.bind(mainMod .. " + M",      hl.dsp.exit())
      hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
      hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd(menu))
      hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())
      hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))

      hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
      hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
      hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

      hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
      hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

      hl.bind(mainMod .. " + A",         hl.dsp.workspace.toggle_special("cookies"))
      hl.bind(mainMod .. " + SHIFT + A", hl.dsp.window.move({ workspace = "special:cookies" }))

      hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

      hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprshot -zm window"))
      hl.bind("ALT + P",         hl.dsp.exec_cmd("hyprshot -zm region"))

      for i = 0, 8 do
          local ws = i + 1
          hl.bind(mainMod .. " + code:1" .. i,             hl.dsp.focus({ workspace = ws}))
          hl.bind(mainMod .. " + SHIFT + code:1" .. i,     hl.dsp.window.move({ workspace = ws }))
      end

      hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
      hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
      hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
      hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

      hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
      hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
      hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
      hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

      -- Window Rules
      hl.window_rule({
          name  = "blueman-float",
          match = { class = [[^(\.blueman.*)$]] },
          float = true,
          move  = "65% 5%",
          size  = "<500 200",
      })

      hl.window_rule({
          name  = "yandex-music-float",
          match = { class = "^(yandex-music)$" },
          float = true,
          size  = "65% 65%",
      })

      hl.window_rule({
          name  = "suppress-maximize",
          match = { class = ".*" },
          suppress_event = "maximize",
      })

      hl.window_rule({
          name  = "fix-xwayland-drags",
          match = {
              class      = "^$",
              title      = "^$",
              xwayland   = true,
              float      = true,
              fullscreen = false,
              pin        = false,
          },
          no_focus = true,
      })

      hl.window_rule({
          name  = "xwayland-border",
          match = { xwayland = true },
          border_color = "rgb(ff5555)",
      })

      hl.window_rule({
          name  = "foot-opacity",
          match = { class = "^(foot)$" },
          opacity = 0.93,
      })

      hl.window_rule({
          name  = "flutter-float",
          match = { class = [[^(com\.example\..+)$]] },
          float = true,
      })

      -- Autostart
      hl.on("hyprland.start", function () 
        hl.exec_cmd("waybar")
        hl.exec_cmd("nm-applet --indicator")
        hl.exec_cmd("[workspace 1 silent] zen")
        hl.exec_cmd("[workspace special:magic silent] Telegram")
      end)
    '';
  };
}
