{ pkgs, ... }:

{
  # powertop --auto-tune fights TLP and breaks USB devices; keep it off.
  powerManagement.powertop.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      # --- CPU frequency scaling -------------------------------------------
      # With an EPP-capable pstate driver (amd-pstate-epp, intel_pstate) the
      # "performance" governor pins EPP to "performance" and ignores
      # CPU_ENERGY_PERF_POLICY_*. The modern,
      # recommended setup is the "powersave" governor on BOTH AC and battery
      # (it still boosts to max) and to steer behaviour via EPP instead.
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Energy Performance Preference (EPP) — this is what actually drives
      # the power/performance trade-off in active mode now.
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

      # Cap sustained performance on battery; full range on AC.
      CPU_MIN_PERF_ON_BAT = 10; # never drop below 10%
      CPU_MAX_PERF_ON_BAT = 80; # cap at 80% to save battery

      # Turbo/boost: full range on AC (the APU needs the headroom to feed the
      # iGPU), off on battery where the extra clocks cost far more than they
      # return.
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # --- Devices ---------------------------------------------------------
      # Runtime power management for PCIe devices (iGPU, NVMe, controllers).
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";

      # Wi-Fi power saving only on battery.
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # PCIe Active State Power Management. "default" is the safe choice;
      # "powersupersave" saves more but can cause instability on some APUs.
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "default";

      SOUND_POWER_SAVE_ON_BAT = 1;

      # USB autosuspend stays OFF: it caused keyd/USB wake-up lag on this unit.
      USB_AUTOSUSPEND = 0;

      # Small extra saving: disable the NMI watchdog.
      NMI_WATCHDOG = 0;

      # Charge thresholds are vendor-specific (name, units and whether they
      # are supported at all), so each host sets its own.
    };
  };

  environment.systemPackages = [ pkgs.powertop ];
}
