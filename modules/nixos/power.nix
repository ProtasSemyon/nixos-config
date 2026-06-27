{ pkgs, ... }:

{
  # AMD Ryzen 7 7735HS (Rembrandt-R) — amd-pstate in active (EPP) mode.
  boot.kernelParams = [
    "amd_pstate=active"
  ];

  # powertop --auto-tune fights TLP and breaks USB devices; keep it off.
  powerManagement.powertop.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      # --- CPU frequency scaling -------------------------------------------
      # With amd-pstate-epp the "performance" governor pins EPP to
      # "performance" and ignores CPU_ENERGY_PERF_POLICY_*. The modern,
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

      # ACPI platform profile (driven by the ideapad_laptop driver). This lets
      # the EC manage power limits and fan curves alongside amd-pstate.
      # Choices on this laptop: low-power | balanced | performance.
      # Use "low-power" on battery for maximum endurance if you don't mind
      # reduced sustained performance.
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";

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

      # Battery charge threshold for IdeaPad (Conservation Mode via the
      # ideapad_laptop driver). 1 = stop charging at ~60% to extend battery
      # lifespan; set to 0 if you need full capacity for travel.
      STOP_CHARGE_THRESH_BAT0 = 1;
    };
  };

  environment.systemPackages = [ pkgs.powertop ];
}
