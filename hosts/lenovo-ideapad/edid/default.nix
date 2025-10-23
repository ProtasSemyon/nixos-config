{ config, lib, pkgs, ... }:
let
  edid-fix = pkgs.stdenv.mkDerivation {
    pname = "edid-fix";
    version = "1.0";
    src = ./edid.bin;
    dontUnpack = true;
    installPhase = ''
        mkdir -p $out/lib/firmware/edid
        cp $src $out/lib/firmware/edid/edid.bin
    '';
  };
in
{
  hardware.display.edid.packages = [ edid-fix ];

  boot.kernelParams = [
    "drm.edid_firmware=eDP-1:edid/edid.bin"
    "drm.edid_override=1"
  ];

}
