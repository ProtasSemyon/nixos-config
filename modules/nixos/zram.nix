{ ... }:

{
  # Compressed swap in RAM. This machine is memory-constrained (16 GiB) and
  # spills several GiB into the on-disk swapfile; zram absorbs that pressure
  # far faster than the SSD and reduces disk wear. zram is given a higher
  # priority than the disk swapfile automatically, so it fills first and the
  # swapfile only acts as overflow.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  boot.kernel.sysctl = {
    # page-cluster = 0 disables swap read-ahead, which is optimal for zram
    # (random access is essentially free, batching only wastes work).
    "vm.page-cluster" = 0;

    # zram swap is cheap (compressed RAM), so prefer pushing anonymous pages to
    # it early instead of evicting the file cache and stalling. 150 is the
    # common tuning for zram-backed systems (kernel allows up to 200).
    "vm.swappiness" = 150;
  };
}
