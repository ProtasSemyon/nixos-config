{ pkgs, ... }:
let
  # Internal panel runs at 120 Hz on AC and drops to 60 Hz on battery to save
  # power. Resolution/scale/position are preserved (only the rate changes), and
  # VRR is intentionally avoided (it tends to flicker on AMD eDP panels).
  edpRefresh = pkgs.writeShellScriptBin "edp-refresh" ''
    set -u
    online=$(cat /sys/class/power_supply/ACAD/online 2>/dev/null || echo 1)
    if [ "$online" = "1" ]; then rate=120; else rate=60; fi

    apply() {
      pos=$(${pkgs.hyprland}/bin/hyprctl -j monitors 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r '.[] | select(.name=="eDP-1") | "\(.x)x\(.y)"')
      [ -n "$pos" ] && [ "$pos" != "null" ] || return 0
      ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1,2880x1800@$rate,$pos,2" >/dev/null
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
  '';
in
{
  environment.systemPackages = [ edpRefresh ];

  systemd.services.edp-refresh = {
    description = "Set internal panel refresh rate based on power source";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${edpRefresh}/bin/edp-refresh";
    };
  };

  # Re-apply on AC plug/unplug.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="${pkgs.systemd}/bin/systemctl start --no-block edp-refresh.service"
  '';
}
