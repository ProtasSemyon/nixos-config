{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    # 32-bit Mesa/RADV — required by Steam, Wine and every 32-bit game.
    enable32Bit = true;

    # The actual drivers (radeonsi for OpenGL/Vulkan-video, RADV for Vulkan)
    # ship with the Mesa that `hardware.graphics.enable` already installs, so
    # only the VA-API/VDPAU glue has to be listed here.
    extraPackages = with pkgs; [
      libva
      libvdpau
      libvdpau-va-gl # VDPAU-only apps on top of VA-API
      libva-vdpau-driver
    ];
  };

  hardware.enableRedistributableFirmware = true;
}
