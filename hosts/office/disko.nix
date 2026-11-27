# Disk layout, applied by nixos-anywhere at install time and turned into
# fileSystems/swapDevices by disko afterwards. Editing this file on an
# installed machine changes mount options, not partitions.
#
#   sda  Crucial BX500 240 GB SSD  ESP (/boot) + btrfs system (/, /home, /nix)
#   sdb  Seagate 1 TB HDD          btrfs, /data
#
# Disks are addressed by /dev/disk/by-id, so the order the kernel happens to
# enumerate them in cannot point the installer at the wrong one.
let
  btrfsOpts = [
    "noatime"
    "compress=zstd"
  ];
in
{
  disko.devices.disk = {
    system = {
      type = "disk";
      device = "/dev/disk/by-id/ata-CT240BX500SSD1_1916E17DB57D";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              extraArgs = [
                "-n"
                "BOOT"
              ];
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-L"
                "nixos"
              ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = btrfsOpts;
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = btrfsOpts;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsOpts;
                };
                # Overflow behind zram, mostly for large builds. A swapfile
                # needs a subvolume of its own: it cannot be snapshotted or
                # compressed.
                "@swap" = {
                  mountpoint = "/swap";
                  swap.swapfile.size = "8G";
                };
              };
            };
          };
        };
      };
    };

    data = {
      type = "disk";
      device = "/dev/disk/by-id/ata-ST1000DM010-2EP102_Z9AVS4AN";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [
              "-f"
              "-L"
              "data"
            ];
            mountpoint = "/data";
            # nofail: a dead HDD must not keep the system disk from booting.
            mountOptions = btrfsOpts ++ [ "nofail" ];
          };
        };
      };
    };
  };
}
