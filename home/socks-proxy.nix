{ pkgs, ... }:

# SOCKS5 proxy on :1080 through an SSH dynamic forward to the VPS. Bound to all
# interfaces, but the NixOS firewall keeps 1080 closed, so from outside the
# laptop it is reachable only over the trusted tailscale interface.
#
# Supervised by systemd instead of `ssh -f`: no fork, and a dropped link (the
# keepalives give up after ~90 s, or the network vanishes over suspend) is just
# a restart.
let
  host = "151.243.182.82";

  # Pinned so the first start on a fresh machine cannot hang on, or blindly
  # accept, an unknown host key.
  knownHosts = pkgs.writeText "socks-proxy-known-hosts" ''
    ${host} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJinDwavd4y82nZRERUHB9V0F5oVRH8lAh98uLnkek/4
  '';
in
{
  systemd.user.services.socks-proxy = {
    Unit = {
      Description = "SOCKS5 proxy on :1080 via SSH to ${host}";
      # Keep retrying however long the network stays down.
      StartLimitIntervalSec = 0;
    };
    Service = {
      ExecStart = builtins.concatStringsSep " " [
        "${pkgs.openssh}/bin/ssh"
        "-N"
        "-D 0.0.0.0:1080"
        "-i %h/.ssh/id_ed25519"
        "-o IdentitiesOnly=yes"
        "-o BatchMode=yes"
        "-o ExitOnForwardFailure=yes"
        "-o ServerAliveInterval=30"
        "-o ServerAliveCountMax=3"
        "-o UserKnownHostsFile=${knownHosts}"
        "-o StrictHostKeyChecking=yes"
        "root@${host}"
      ];
      Restart = "always";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
