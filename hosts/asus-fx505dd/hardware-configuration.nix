# This machine has two SSDs and dual-boots Windows:
#
#   nvme0n1 (119 GB)  Windows' ESP + C:          — NixOS does not touch this disk
#   sda (931 GB)      sda2  D: (NTFS, no label)  — mounted read-only below
#                     sda3  NIXBOOT (vfat)       — /boot, NixOS' own ESP
#                     sda4  nixos (btrfs)        — /
#
# NixOS gets its own ESP on its own disk rather than borrowing Windows'. Two
# ESPs on one machine is fine — the firmware lists a boot entry per disk — and
# it means nothing is ever written to the Windows disk, so reinstalling either
# OS cannot break the other.
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
  };

  # fmask/dmask keep the ESP out of reach of non-root users, which is the
  # current NixOS recommendation.
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Windows' D: partition. Only the NixOS partitions were labeled at install
  # time, so this one is addressed by UUID instead. nofail keeps a missing or
  # dirty volume from blocking boot; it mounts read-only anyway unless Fast
  # Startup and hibernation are off in Windows.
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/AA2429E12429B0ED";
    fsType = "ntfs3";
    options = [
      "nofail"
      "uid=1000"
      "gid=100"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
