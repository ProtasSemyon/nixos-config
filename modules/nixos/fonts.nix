{ lib, pkgs, ... }:

{
  fonts.packages = [
    pkgs.font-awesome
  ]
  ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  fonts.fontconfig.useEmbeddedBitmaps = true;
}
