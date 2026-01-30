{
  pkgs,
  lib,
  fetchurl,
}:
let
  version = "1.9.4";
  pname = "siruslauncher";
  src = fetchurl {
    url = "https://github.com/sirussu/open-launcher/releases/download/v${version}/SirusLauncher-${version}.AppImage";
    hash = "sha256-yojj8WHmlIdiTWJfjuX+IZrtxQ0fFAqSKIGdsUF7/TE=";
  };
in
pkgs.appimageTools.wrapType2 {
  inherit pname version src;
}
