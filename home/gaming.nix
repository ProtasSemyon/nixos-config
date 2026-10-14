{ pkgs, osConfig, ... }:

let
  gamescope-auto = pkgs.callPackage ../pkgs/gamescope-auto.nix { };
in
{
  programs.lutris = {
    enable = true;

    # Must be the very same derivation the NixOS module installs — otherwise
    # Lutris' FHS sandbox pulls in a second, conflicting Steam.
    steamPackage = osConfig.programs.steam.package;

    # Visible inside Lutris' FHS sandbox. Lutris ships its own DXVK/VKD3D and
    # downloads its own wine-ge builds, so only the tooling around them is
    # needed here.
    extraPackages =
      (with pkgs; [
        winetricks
        gamemode
        gamescope
        mangohud
        umu-launcher # the runtime Lutris uses to start Proton prefixes
        vulkan-tools
      ])
      # Set this as the game's command prefix (`gamescope-auto --`) so gamescope
      # follows whichever monitor the session is on instead of defaulting to 720p.
      ++ [ gamescope-auto ];

    # Wine/Proton versions offered in the runner dropdown. Proton-GE is the
    # sensible default for anything that is not an old Win32 title.
    protonPackages = [ pkgs.proton-ge-bin ];
    winePackages = [ pkgs.wineWow64Packages.waylandFull ];
    defaultWinePackage = pkgs.proton-ge-bin;
  };

  # Overlay for FPS/frame-time/thermals. Not enabled session-wide on purpose —
  # it is opt-in per game via `mangohud %command%` or Lutris' toggle, so it
  # doesn't attach itself to every GTK app on the desktop.
  programs.mangohud = {
    enable = true;
    settings = {
      fps = true;
      frametime = true;
      frame_timing = 1;
      # 1% / 0.1% lows say far more about stutter than the average does.
      fps_metrics = [
        "avg"
        "0.01"
        "0.001"
      ];

      gpu_stats = true;
      gpu_temp = true;
      gpu_power = true;
      gpu_load_change = true;
      cpu_stats = true;
      cpu_temp = true;
      cpu_load_change = true;

      # On an iGPU "VRAM" is the 2 GiB UMA carve-out and RAM is everything
      # else — watching both is how you catch a game spilling into GTT.
      vram = true;
      ram = true;
      swap = true;

      battery = true;
      gamemode = true;
      vulkan_driver = true;
      wine = true;
      fsr = true;

      position = "top-left";
      font_size = 20;
      background_alpha = 0.4;

      toggle_hud = "Shift_R+F12";
      toggle_fps_limit = "Shift_R+F1";
      # Cycle uncapped / 60 / 40. A stable 40 fps beats a 45-55 fps sawtooth on
      # a power-limited APU, and it keeps the fans quiet.
      fps_limit = [
        0
        60
        40
      ];
      fps_limit_method = "late";
    };
  };
}
