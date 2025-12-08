{ pkgs, ... }:

{
  services = {
    xserver.enable = true;
    displayManager.defaultSession = "plasmax11";
    desktopManager.plasma6.enable = true;
    desktopManager.plasma6.enableQt5Integration = true;
  };
}
