{ ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      # Key-based auth only (this host is reachable over Tailscale; physical
      # access remains available, so there is no lockout risk).
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  # office's host key was generated before install (it is also its sops
  # identity), so it can be trusted up front instead of on first connect.
  programs.ssh.knownHosts.office = {
    hostNames = [
      "office"
      "office.tail883758.ts.net"
      "100.72.229.113"
    ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGzAzlHZX79xAHz5m57iK6SOaPK5PoHSYf8zWTbB0AyF";
  };

  services.printing.enable = true;
  services.libinput.enable = true;
  services.fwupd.enable = true;

  # Cap the systemd journal so logs can't grow without bound.
  services.journald.settings.Journal.SystemMaxUse = "500M";

  services.deluge = {
    enable = true;
    web.enable = true;
  };
}
