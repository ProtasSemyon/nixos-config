{ pkgs, inputs, ... }:

{
  imports = [
    ./hyprpaper.nix
    ./lock.nix
  ];

  hyprpaper = {
    enable = true;
    wallpaper = "MagicForest.png";
  };

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
  xdg.configFile."hypr/hyprland.lua".text = builtins.readFile ./hyprland.lua;
}
