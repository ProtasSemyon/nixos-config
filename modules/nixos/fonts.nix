{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Pinned nixpkgs (see flake.nix), so a system update does not re-download
  # fonts whose files have not changed.
  fontPkgs = import inputs.nixpkgs-fonts {
    inherit (pkgs.stdenv.hostPlatform) system;
    inherit (pkgs) config;
  };
in
{
  fonts.packages = [
    fontPkgs.font-awesome
    fontPkgs.inter
  ]
  ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues fontPkgs.nerd-fonts);

  fonts.fontconfig.useEmbeddedBitmaps = true;
}
