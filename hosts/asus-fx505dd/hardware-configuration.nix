# PLACEHOLDER — replace with the file `nixos-generate-config --root /mnt`
# produces on the actual machine, keeping the mount points below.
#
# This machine has two SSDs and dual-boots Windows:
#
#   128 GB SSD   Windows' ESP + C:          — NixOS does not touch this disk
#   1 TB SSD     D: (NTFS, first half)      — left alone
#                NIXBOOT (vfat, 2 GiB)      — /boot, NixOS' own ESP
#                nixos   (btrfs, the rest)  — /
#
# NixOS gets its own ESP on its own disk rather than borrowing Windows'. Two
# ESPs on one machine is fine — the firmware lists a boot entry per disk — and
# it means nothing is ever written to the Windows disk, so reinstalling either
# OS cannot break the other. It also removes the reason to keep /boot separate
# from the ESP: this one is sized for it.
#
# Devices are addressed by label because the UUIDs do not exist until the disk
# is formatted; check them with `lsblk -o NAME,SIZE,FSTYPE,LABEL`.
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

  # NVMe slot plus the 2.5" SATA bay — one SSD is in each.
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
    "rtsx_pci_sdmmc"
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

  # To get at the Windows data partition from NixOS, add something like this
  # once its label is known. nofail keeps a missing or dirty volume from
  # blocking boot; it mounts read-only anyway unless Fast Startup and
  # hibernation are off in Windows.
  #
  # fileSystems."/mnt/data" = {
  #   device = "/dev/disk/by-label/<D: label>";
  #   fsType = "ntfs3";
  #   options = [ "nofail" "uid=1000" "gid=100" ];
  # };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
