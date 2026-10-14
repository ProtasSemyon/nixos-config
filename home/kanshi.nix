{ pkgs, ... }:

{
  # Output hotplug profiles. The profiles are per-machine — they key off the
  # built-in panel's name and the serial numbers of the external displays — so
  # each host supplies `services.kanshi.settings` from its own
  # hosts/<host>/home.nix.
  services.kanshi.enable = true;

  home.packages = [ pkgs.kanshi ];
}
