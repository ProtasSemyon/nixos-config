{ pkgs, ... }:

let
  # Resolves the focused monitor and hands gamescope its real pixel geometry;
  # see pkgs/gamescope-auto.nix for why that cannot be left to gamescope.
  gamescope-auto = pkgs.callPackage ../../pkgs/gamescope-auto.nix { };
in
{
  # ---------------------------------------------------------------------------
  # Steam
  # ---------------------------------------------------------------------------
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    protontricks.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    # Proton-GE carries the DXVK/VKD3D patches and the media codecs that stock
    # Proton lacks. It shows up as an extra entry in the per-game compatibility
    # tool dropdown; nothing switches to it automatically.
    extraCompatPackages = [ pkgs.proton-ge-bin ];

    # Visible inside Steam's FHS sandbox, so `mangohud %command%` and
    # `gamemoderun %command%` work as launch options.
    extraPackages =
      (with pkgs; [
        mangohud
        gamemode
        gamescope
      ])
      ++ [ gamescope-auto ];
  };

  # ---------------------------------------------------------------------------
  # gamescope
  # ---------------------------------------------------------------------------
  # The main lever on a 12 CU iGPU: render the game below native and let FSR
  # upscale. Use the wrapper as a launch option -- `gamescope-auto -- %command%`
  # -- and set GAMESCOPE_SCALE=0.66 to trade resolution for frame rate.
  programs.gamescope = {
    enable = true;
    # Without CAP_SYS_NICE gamescope cannot raise its own scheduling priority
    # and ends up competing with the game for CPU, which shows as frame-time
    # jitter rather than lower average FPS.
    capSysNice = true;
  };

  # ---------------------------------------------------------------------------
  # gamemode
  # ---------------------------------------------------------------------------
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        softrealtime = "auto";
        inhibit_screensaver = 1;
      };

      # The per-GPU section (`gpu.gpu_device`, `amd_performance_level`) is
      # set per host: the card index and whether pinning the DPM level helps
      # both depend on the machine.

      custom = {
        start = "${pkgs.libnotify}/bin/notify-send -a GameMode 'GameMode activated'";
        end = "${pkgs.libnotify}/bin/notify-send -a GameMode 'GameMode deactivated'";
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Wine / Proton runtime
  # ---------------------------------------------------------------------------
  # ntsync implements NT synchronisation primitives in the kernel; it replaces
  # the esync/eventfd and fsync/futex hacks and is both faster and more correct
  # for Wine >= 10 / Proton >= 10. The module exists in 6.18 but is not
  # autoloaded, and the device node is root-only by default.
  boot.kernelModules = [ "ntsync" ];
  services.udev.extraRules = ''
    KERNEL=="ntsync", MODE="0660", TAG+="uaccess"
  '';

  environment.sessionVariables = {
    # Opt in for Proton 10+; older Proton builds ignore the variable.
    PROTON_USE_NTSYNC = "1";
  };

  # Also on PATH outside the Steam/Lutris sandboxes, for games launched by hand.
  environment.systemPackages = [ gamescope-auto ];

  boot.kernel.sysctl = {
    # Windows games regularly execute split-lock instructions. The kernel's
    # default mitigation throttles the offending thread to roughly one such
    # operation per 10 ms, which is visible as heavy stutter. This knob is
    # DoS hardening against untrusted local code, not a security boundary.
    "kernel.split_lock_mitigate" = 0;
  };
}
