{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
  };
  
  boot.plymouth.enable = true;
  boot.plymouth.theme = "bgrt";
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;
  boot.kernelParams = [ 
    "quiet" 
    "udev.log_level=0" 
    "amdgpu.dcdebugmask=0x10"
    "amdgpu.sg_display=0"
    "amdgpu.abmlevel=0"
  ];

}
