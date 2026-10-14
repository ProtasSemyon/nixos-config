{ ... }:

{
  # Common NixOS modules enabled on every host.
  # Optional modules (godot.nix, ciscoPacketTracer.nix, kde.nix) are imported
  # per-host as needed.
  imports = [
    ./boot.nix
    ./nix.nix
    ./networking.nix
    ./locale.nix
    ./fonts.nix
    ./bluetooth.nix
    ./graphics.nix
    ./virtualisation.nix
    ./shell.nix
    ./nh.nix
    ./programs.nix
    ./secrets.nix
    ./services.nix
    ./users.nix
    ./desktop.nix
    ./display-refresh.nix
    ./packages.nix
    ./pipewire.nix
    ./power.nix
    ./zram.nix
    ./gaming.nix
    ./thunar.nix
    ./obs.nix
  ];
}
