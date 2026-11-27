{ pkgs, inputs, ... }:

let
  # claude-code comes from its own nixpkgs input (see flake.nix), so it can be
  # updated on its own. `config` is inherited from the host so allowUnfree --
  # which claude-code needs -- still applies.
  claudePkgs = import inputs.nixpkgs-claude {
    inherit (pkgs.stdenv.hostPlatform) system;
    inherit (pkgs) config;
  };
in
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
    vulkan-tools
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

    pinentry-gnome3
    toybox

    libva
    libva-utils

    clang
    sshfs

    google-chrome

    claudePkgs.claude-code
    antigravity-cli

    netbird-ui
    grpcurl

    postgresql # client tools only (psql, pg_dump); no server is enabled
    awscli2
    kubectl
    kubernetes-helm
    glab

    codex

    # System-wide (not home-manager) so polkit sees its policy and Quick Unlock works
    keepassxc
  ];
}
