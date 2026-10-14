{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # Power-cycles DPMS on a monitor — the quickest way to shake the panel out of
  # a bad state (stuck/garbled/blank output) without restarting the session.
  screenReset = pkgs.writeShellScriptBin "screen-reset" ''
    set -u
    mon=''${1:-${defaultMonitor}}

    on() { ${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.dpms(\"on\", \"$mon\")" >/dev/null; }
    # Never leave the panel dark if we get killed mid-cycle.
    trap on EXIT INT TERM

    ${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.dpms(\"off\", \"$mon\")" >/dev/null
    sleep 2
  '';

  # The monitor screen-reset acts on when called without an argument.
  defaultMonitor =
    if config.hyprland.monitors == [ ] then "" else (builtins.head config.hyprland.monitors).output;

  # `hl.monitor({...})` calls, generated from the host's monitor list and
  # prepended to the shared Lua config below.
  monitorsLua = lib.concatMapStrings (m: ''
    hl.monitor({
      output   = "${m.output}",
      mode     = "${m.mode}",
      position = "${m.position}",
      scale    = "${m.scale}",
    })
  '') config.hyprland.monitors;
in
{
  imports = [
    ./hyprpaper.nix
    ./lock.nix
    ./swaync.nix
  ];

  options.hyprland.monitors = lib.mkOption {
    default = [ ];
    description = ''
      Monitors to declare at the top of the Hyprland Lua config. This is
      per-machine, so hosts set it from their own hosts/<host>/home.nix.
      Runtime hotplug layouts are kanshi's job (see home/kanshi.nix); this
      list only establishes the startup state of the built-in panel.
    '';
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          output = lib.mkOption {
            type = lib.types.str;
            example = "eDP-1";
            description = "Hyprland output name.";
          };
          mode = lib.mkOption {
            type = lib.types.str;
            example = "2880x1800@120";
            description = "Resolution and refresh rate, or \"preferred\".";
          };
          position = lib.mkOption {
            type = lib.types.str;
            default = "auto";
            description = "Position in the layout, or \"auto\".";
          };
          scale = lib.mkOption {
            type = lib.types.str;
            default = "auto";
            description = "Scale factor, or \"auto\".";
          };
        };
      }
    );
  };

  config = {
    hyprpaper = {
      enable = true;
      wallpaper = "MagicForest.png";
    };

    services.hyprpolkitagent.enable = true;
    services.gammastep = {
      enable = true;

      dawnTime = "6:00-7:45";
      duskTime = "18:35-20:15";

      temperature = {
        day = 5500;
        night = 3400;
      };
    };

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
      blueman
      cliphist
      brightnessctl

      wl-clipboard-rs
      dmenu

      libnotify

      screenReset

      inputs.hyprland-guiutils.packages.${stdenv.hostPlatform.system}.default
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      extraConfig = "-- Lua config is handled via xdg.configFile";
    };

    # Hyprland's new Lua config (the hl.* API). Kept as a real .lua file for
    # editor syntax highlighting and linting. Uses readFile (not `source`) so it
    # still concatenates with the Home Manager module's generated footer — which
    # starts hyprland-session.target and propagates the session environment.
    # The per-host monitor declarations are generated above and prepended.
    xdg.configFile."hypr/hyprland.lua".text = monitorsLua + "\n" + builtins.readFile ./hyprland.lua;
  };
}
