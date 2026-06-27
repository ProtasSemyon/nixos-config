{ username, ... }:

{
  # nh — a nicer front-end for nixos-rebuild: shows a package diff before
  # switching and manages generation cleanup.
  programs.nh = {
    enable = true;
    flake = "/home/${username}/nixos-config";

    clean = {
      enable = true;
      extraArgs = "--keep 5 --keep-since 7d";
    };
  };
}
