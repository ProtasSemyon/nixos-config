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
    # it early instead of evicting the file cache and stalling. 150-200 is the
    # common tuning for zram-backed systems (kernel allows up to 200).
    "vm.swappiness" = 180;

    # Keep a wider free-memory margin so kswapd reclaims in the background
    # instead of the allocating task stalling in direct reclaim. The unit is
    # 1/10000 of a zone, so 200 reserves roughly 2% (~280 MiB here) against
    # the default 0.1%, which is far too thin for bursty desktop allocations.
    "vm.watermark_scale_factor" = 200;
  };
}
