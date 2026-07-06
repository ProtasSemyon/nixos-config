{ pkgs, inputs, ... }:

{
  # System-wide packages. To search, run: nix search wget
  environment.systemPackages = with pkgs; [
    lm_sensors
    fzf
    valgrind
    appimage-run
    vim
    wget
    btop
    mesa
    vulkan-tools
    pipewire
    wireplumber
    pamixer
    pulseaudio # даёт pactl для просмотра bluez-профилей

    # Nix tooling
    nix-prefetch-github
    nixd
    nil
    nix-ld

    # Theme
    sddm-astronaut
    catppuccin-sddm

    slack

    docker-compose

    volantes-cursors

    graalvmPackages.graalvm-oracle

    pinentry-gtk2
    toybox

    libva
    libva-utils

    clang
    sshfs

    inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
    google-chrome

    claude-code

    netbird-ui
  ];
}
