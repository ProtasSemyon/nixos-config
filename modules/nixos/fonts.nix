{ lib, pkgs, ... }:

{
  fonts.packages = [
    pkgs.font-awesome
    pkgs.inter
  ]
  ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  fonts.fontconfig.useEmbeddedBitmaps = true;
}
