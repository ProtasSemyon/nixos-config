{ config, ... }:

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

  networking.networkmanager.unmanaged = [ config.services.tailscale.interfaceName ];
  networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
}
