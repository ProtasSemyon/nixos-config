{ username, ... }:

{
  imports = [
    ./packages.nix
    ./theme.nix
    ./fish.nix
    ./git.nix
    ./rust.nix
    ./foot.nix
    ./ssh.nix
    ./kanshi.nix
    ./waybar.nix
    ./hyprland
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.stateVersion = "26.05";
  home.enableNixpkgsReleaseCheck = false;

  home.sessionVariables = {
    GOOGLE_CLOUD_PROJECT = "clear-backup-483414-t5";
    GOOGLE_CLOUD_PROJECT_ID = "clear-backup-483414-t5";

    MOZ_ENABLE_WAYLAND = "1";
    MOZ_X11_EGL = "1";
    MOZ_DISABLE_RDD_SANDBOX = "1";
    LIBVA_DRIVER_NAME = "radeonsi";
  };

  # Thunar/xfce: use foot as the default terminal emulator.
  home.file.".config/xfce4/helpers.rc".text = ''
    TerminalEmulator=foot
  '';

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
