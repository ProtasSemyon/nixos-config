{ pkgs, ... }:
{
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  programs.hyprland.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = [
    (pkgs.waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      })
    )
    
    pkgs.libnotify

    pkgs.hyprpaper
    pkgs.hyprsunset
    pkgs.rofi-wayland
    pkgs.wl-clipboard-rs

    pkgs.hyprshot
  ];

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  services.xserver.videoDrivers = [ "amdgpu" ];

  xdg.portal.enable = true;

  home-manager.users.smn = {
    services.hyprpolkitagent.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # wayland.windowManager.hyprland = {
    #   enable = true;

    #   package = null;
    #   portalPackage = null;
    # };
  };
}
