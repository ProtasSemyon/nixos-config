{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      libva
      libvdpau
      libvdpau-va-gl
      libva-vdpau-driver
      libva-utils
    ];
  };

  hardware.enableRedistributableFirmware = true;
}
