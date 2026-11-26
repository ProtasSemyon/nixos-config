{ config, pkgs, ... }:

# Alarm clock, driven from the command line:
#
#   alarm 06:30 [label]   next 06:30 (today or tomorrow)
#   alarm +20m  [label]   relative, anything `date -d "now +20 min"` takes
#   alarm list
#   alarm cancel [unit…]  no argument cancels every pending alarm
#   alarm stop            silence the one that is ringing
#
# Each alarm is a transient user timer (`systemd-run --user`), so nothing is
# stored anywhere and a rebuild is never needed. `WakeSystem=true` arms an RTC
# alarm when the machine suspends; that needs CAP_WAKE_ALARM, which the user
# manager already holds (systemd ≥254 grants it to local sessions). The polkit
# rule in modules/nixos/alarm.nix lets the ringing process hold the lid and
# sleep inhibitors, so logind does not put a closed laptop straight back to
# sleep after the alarm woke it.
#
# Transient units do not survive a reboot or logout: an alarm set before a
# shutdown is gone. That is the price of not keeping state.
let
  sound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga";

  # Stop ringing on its own after this long; the alarm then snoozes once more.
  ringFor = 600;
  snoozeMin = 5;

  alarm = pkgs.writeShellApplication {
    name = "alarm";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      libnotify
      pipewire
      wireplumber
      systemd
      hyprland
    ];
    text = ''
      # Use the profile copy when it exists, so a pending alarm does not pin
      # a store path that a garbage collection could remove before it fires.
      self=${config.home.profileDirectory}/bin/alarm
      [ -x "$self" ] || self=$(readlink -f "$0")

      usage() {
        cat <<'EOF'
      alarm HH:MM [label]    ring at the next HH:MM
      alarm +20m [label]     ring in 20 minutes (m, h, or anything date -d accepts)
      alarm list             pending alarms
      alarm cancel [unit…]   cancel the given alarms, or all of them
      alarm stop             silence the alarm that is ringing
      EOF
      }

      set_alarm() {
        local when=$1 label=''${2:-Будильник} target now
        now=$(date +%s)
        case "$when" in
          +*)
            local rel=''${when#+}
            rel=''${rel/%m/ min}
            rel=''${rel/%h/ hour}
            target=$(date -d "now + $rel" +%s)
            ;;
          *)
            target=$(date -d "$when" +%s)
            [ "$target" -gt "$now" ] || target=$(date -d "$when tomorrow" +%s)
            ;;
        esac

        local unit stamp
        stamp=$(date -d "@$target" '+%Y-%m-%d %H:%M:%S')
        unit="alarm-$(date -d "@$target" +%Y%m%d-%H%M%S)"
        systemd-run --user --quiet \
          --unit="$unit" \
          --description="$label" \
          --on-calendar="$stamp" \
          --timer-property=WakeSystem=true \
          --timer-property=AccuracySec=1s \
          --property=Type=exec \
          "$self" ring "$label"
        local left=$(( (target - now + 59) / 60 ))
        printf '%s  %s  (через %dч %02dм)  [%s]\n' \
          "$(date -d "@$target" '+%a %H:%M')" "$label" $((left / 60)) $((left % 60)) "$unit"
      }

      list() {
        local found=0 t
        for t in $(systemctl --user list-units --plain --no-legend --all 'alarm-*.timer' | cut -d' ' -f1); do
          found=1
          printf '%s  %s  [%s]\n' \
            "$(systemctl --user show -p NextElapseUSecRealtime --value "$t")" \
            "$(systemctl --user show -p Description --value "''${t%.timer}.service")" \
            "''${t%.timer}"
        done
        [ "$found" = 1 ] || echo "Будильников нет."
      }

      cancel() {
        if [ $# -eq 0 ]; then
          systemctl --user stop 'alarm-*.timer'
        else
          local u
          for u in "$@"; do systemctl --user stop "''${u%.timer}.timer"; done
        fi
      }

      ring() {
        local label=''${1:-Будильник} pids=()

        # Unmute and make sure it is audible; put the old level back after.
        local vol muted
        vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)
        muted=0; grep -q MUTED <<<"$vol" && muted=1
        vol=$(grep -oE '[0-9]+\.[0-9]+' <<<"$vol" || echo 0.5)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 || true
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.6 --limit 1.0 || true

        restore() {
          kill "''${pids[@]}" 2>/dev/null || true
          wpctl set-volume @DEFAULT_AUDIO_SINK@ "$vol" || true
          [ "$muted" = 0 ] || wpctl set-mute @DEFAULT_AUDIO_SINK@ 1 || true
        }
        trap restore EXIT
        trap 'exit 0' TERM INT

        # Hold off sleep, idle and the lid switch while ringing. Without the
        # polkit rule this fails; ring anyway rather than stay silent.
        systemd-inhibit --what=sleep:idle:handle-lid-switch --mode=block \
          --who=alarm --why="$label" sleep infinity 2>/dev/null &
        pids+=($!)

        hyprctl dispatch 'hl.dsp.dpms({ action = "on" })' >/dev/null 2>&1 || true

        # Rising volume: 20 % of the stream volume up to 100 % over ~1 min.
        (
          v=20
          while :; do
            pw-play --volume "$(printf '0.%02d' "$v")" ${sound} 2>/dev/null \
              || pw-play ${sound} || sleep 2
            [ "$v" -ge 99 ] || v=$((v + 8))
            [ "$v" -le 99 ] || v=99
          done
        ) &
        pids+=($!)

        local action
        action=$(timeout ${toString ringFor} notify-send --wait -u critical \
          -a "Будильник" -i alarm-symbolic \
          -A stop="Стоп" -A snooze="+${toString snoozeMin} мин" \
          "$label" "$(date +%H:%M)" || echo snooze)

        case "$action" in
          snooze) set_alarm "+${toString snoozeMin}m" "$label" >/dev/null ;;
        esac
      }

      case "''${1:-}" in
        list | ls) list ;;
        cancel | rm) shift; cancel "$@" ;;
        stop) systemctl --user kill --signal=TERM 'alarm-*.service' ;;
        ring) shift; ring "$@" ;;
        "" | -h | --help | help) usage ;;
        *) set_alarm "$@" ;;
      esac
    '';
  };
in
{
  home.packages = [ alarm ];
}
