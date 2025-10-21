{ config, lib, pkgs, inputs, system, ... }:

{
  hardware.display.edid.packages = [ inputs.edid-fix.packages."${system}".default ];

  boot.kernelParams = [
    "drm.edid_firmware=eDP-1:edid/edid.bin"
    "drm.edid_override=1"
  ];

}
