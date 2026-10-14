{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
  };

  distro-grub-themes = {
    enable = true;
    theme = "nixos";
  };

  # Wipe /tmp on every boot (it lives on the SSD, not tmpfs, so this is safe
  # on a RAM-constrained machine).
  boot.tmp.cleanOnBoot = true;

  boot.plymouth.enable = true;
  boot.plymouth.theme = "bgrt";
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;
  boot.kernelParams = [
    "quiet"
    "udev.log_level=0"
  ];
}
