{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.display.internal;

  # The built-in panel runs at its high refresh rate on AC and drops to the
  # battery rate on DC to save power. Resolution/scale/position are preserved
  # (only the rate changes), and VRR is intentionally avoided (it tends to
  # flicker on AMD eDP panels).
  #
  # The command is installed on every host, including those without a built-in
  # panel: the Hyprland autostart and the kanshi profiles call it
  # unconditionally, so it has to exist and succeed either way.
  edpRefresh = pkgs.writeShellScriptBin "edp-refresh" (
    if cfg.output == null then
      ''
        # This host has no built-in panel; nothing to switch.
        exit 0
      ''
    else
      ''
        set -u
        online=$(cat /sys/class/power_supply/${cfg.acDevice}/online 2>/dev/null || echo 1)
        if [ "$online" = "1" ]; then rate=${toString cfg.refreshRate.ac}; else rate=${toString cfg.refreshRate.battery}; fi

        apply() {
          pos=$(${pkgs.hyprland}/bin/hyprctl -j monitors 2>/dev/null \
            | ${pkgs.jq}/bin/jq -r '.[] | select(.name=="${cfg.output}") | "\(.x)x\(.y)"')
          [ -n "$pos" ] && [ "$pos" != "null" ] || return 0
          ${pkgs.hyprland}/bin/hyprctl keyword monitor "${cfg.output},${cfg.mode}@$rate,$pos,${cfg.scale}" >/dev/null
        }

        if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          apply
        else
          # Called outside a Hyprland session (e.g. from the udev/systemd hook):
          # reach every running user instance.
          for sock in /run/user/*/hypr/*/.socket.sock; do
            [ -e "$sock" ] || continue
            HYPRLAND_INSTANCE_SIGNATURE=$(basename "$(dirname "$sock")")
            XDG_RUNTIME_DIR=''${sock%/hypr/*}
            export HYPRLAND_INSTANCE_SIGNATURE XDG_RUNTIME_DIR
            apply
          done
        fi
      ''
  );
in
{
  # Facts about the built-in panel. Every host that has one sets these in its
  # own hosts/<host>/default.nix; hosts without one leave `output` at null.
  options.host.display.internal = {
    output = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "eDP-1";
      description = ''
        Kernel/Hyprland name of the built-in panel, or null on a machine that
        has none (desktop, or a laptop whose panel needs no rate switching).
      '';
    };

    mode = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "2880x1800";
      description = "Panel resolution, without the refresh rate suffix.";
    };

    scale = lib.mkOption {
      type = lib.types.str;
      default = "1";
      example = "2";
      description = "Hyprland scale factor applied to the panel.";
    };

    refreshRate = {
      ac = lib.mkOption {
        type = lib.types.int;
        default = 60;
        description = "Refresh rate (Hz) to use while on mains power.";
      };

      battery = lib.mkOption {
        type = lib.types.int;
        default = 60;
        description = "Refresh rate (Hz) to use while on battery.";
      };
    };

    acDevice = lib.mkOption {
      type = lib.types.str;
      default = "ACAD";
      example = "AC0";
      description = ''
        Name of the mains adapter under /sys/class/power_supply. ACPI firmware
        is inconsistent here — ACAD, AC and AC0 are all in use.
      '';
    };
  };

  config = {
    environment.systemPackages = [ edpRefresh ];

    systemd.services.edp-refresh = lib.mkIf (cfg.output != null) {
      description = "Set internal panel refresh rate based on power source";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${edpRefresh}/bin/edp-refresh";
      };
    };

    # Re-apply on AC plug/unplug.
    services.udev.extraRules = lib.mkIf (cfg.output != null) ''
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="${pkgs.systemd}/bin/systemctl start --no-block edp-refresh.service"
    '';
  };
}
