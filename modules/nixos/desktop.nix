{ pkgs, ... }:

{
  # System-side desktop session. The user-facing Hyprland configuration lives
  # in the Home Manager module (home/hyprland).
  programs.hyprland.enable = true;

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

  xdg.portal.enable = true;

  # Let hyprlock authenticate via PAM (required to unlock the screen).
  security.pam.services.hyprlock = { };

  # Lid behaviour: suspend on battery, just lock on AC, keep running when
  # docked to an external display (HandleLidSwitchDocked defaults to "ignore").
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    HYPRSHOT_DIR = "$HOME/Pictures/Screenshots";
  };
}
