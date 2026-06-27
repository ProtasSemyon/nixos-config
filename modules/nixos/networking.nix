{ config, pkgs, ... }:

{
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  services.resolved.enable = true;

  # The office WireGuard profile ("vpn") pushes an in-tunnel DNS server, so at
  # boot DNS breaks until the tunnel is actually up (internet works by IP, names
  # don't — hence the "disable VPN, ping, re-enable" workaround). Re-activate the
  # VPN whenever a physical uplink finishes coming up: this re-resolves the
  # endpoint with working DNS and fixes both the boot race and Wi-Fi roaming.
  networking.networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.writeShellScript "vpn-reconnect" ''
        interface="$1"
        action="$2"
        case "$interface" in
          wlp* | wlan* | enp* | eth* | end*) ;;
          *) exit 0 ;;
        esac
        if [ "$action" = "up" ]; then
          ${pkgs.networkmanager}/bin/nmcli connection up vpn || true
        fi
      '';
    }
  ];

  networking.firewall.checkReversePath = "loose";

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "both";
  };

  networking.networkmanager.unmanaged = [ config.services.tailscale.interfaceName ];
  networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
}
