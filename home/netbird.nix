{ osConfig, pkgs, ... }:

# The management server expires SSO peers after 24 hours, and an expired peer
# drops the tunnel until someone logs in again. The expiry itself is server
# policy and cannot be lifted from here; this only makes renewing it a matter of
# answering a browser tab ahead of time instead of noticing the VPN is gone.
#
# `netbird login --extend` refreshes the session without tearing the tunnel
# down, but it needs a live connection, so it is only attempted inside the
# window before expiry. Once the session has already lapsed the daemon reports
# SessionExpired/NeedsLogin and only a full `netbird up` brings it back.
let
  netbird = "${osConfig.services.netbird.clients.default.wrapper}/bin/netbird";

  # Renew once less than this many seconds remain.
  window = 3600;

  renew = pkgs.writeShellApplication {
    name = "netbird-renew";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
      pkgs.libnotify
    ];
    text = ''
      status=$(${netbird} status --json) || exit 0
      daemon=$(jq -r .daemonStatus <<<"$status")
      expires=$(jq -r '.sessionExpiresAt // empty' <<<"$status")

      notify() {
        notify-send -a NetBird -i network-vpn "$1" "$2"
      }

      case "$daemon" in
        Connected)
          # Peers added with a setup key, or with expiry disabled, carry no date.
          [ -n "$expires" ] || exit 0
          left=$(( $(date -d "$expires" +%s) - $(date +%s) ))
          [ "$left" -lt ${toString window} ] || exit 0
          notify "NetBird session expires in $(( left / 60 )) min" \
            "Log in in the browser tab to extend it."
          ${netbird} login --extend
          ;;
        SessionExpired | NeedsLogin)
          notify "NetBird session expired" "Log in in the browser tab to reconnect."
          ${netbird} up
          ;;
        # Idle is a deliberate `netbird down`; leave it alone, along with the
        # transient states.
      esac
    '';
  };
in
{
  systemd.user.services.netbird-renew = {
    Unit.Description = "Extend the NetBird SSO session before it expires";
    Service = {
      Type = "oneshot";
      ExecStart = "${renew}/bin/netbird-renew";
      # The CLI waits for the browser login; give up on an ignored tab so the
      # next tick can reopen it.
      TimeoutStartSec = "10min";
    };
  };

  systemd.user.timers.netbird-renew = {
    Unit.Description = "Check the NetBird session expiry";
    Timer = {
      # Wall-clock, so a run missed during suspend fires right after resume.
      OnCalendar = "*:0/15";
      Persistent = true;
    };
    # The login opens a browser, so only run inside a graphical session.
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
