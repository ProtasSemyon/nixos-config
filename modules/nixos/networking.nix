{ config, pkgs, ... }:

{
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  services.resolved.enable = true;

  networking.firewall.checkReversePath = "loose";

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "both";
  };

  services.netbird.enable = true;

  # Netbird's policy rule (priority 110) sends whole subnets and public IPs —
  # the office's among them — into its tunnel, ahead of Tailscale's own rules
  # (5210+). Tailscale's NAT-traversal packets to a peer behind such an address
  # then never arrive, and the connection is stuck on a DERP relay (~300 ms
  # instead of ~50 ms direct). Packets carrying Tailscale's bypass mark go by
  # the main table before Netbird sees them; everything else, including
  # traffic to the work networks, still takes the Netbird tunnel.
  systemd.services.tailscale-bypass-netbird = {
    description = "Route Tailscale's own packets around the Netbird tunnel";
    after = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.iproute2 ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for f in -4 -6; do
        ip $f rule del priority 100 2>/dev/null || true
        ip $f rule add priority 100 fwmark 0x80000/0xff0000 lookup main
      done
    '';
    preStop = ''
      for f in -4 -6; do ip $f rule del priority 100 2>/dev/null || true; done
    '';
  };

  networking.networkmanager.unmanaged = [ config.services.tailscale.interfaceName ];
  networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
}
