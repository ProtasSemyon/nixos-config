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
  services.printing.enable = true;
  services.libinput.enable = true;
  services.fwupd.enable = true;

  # Cap the systemd journal so logs can't grow without bound.
  services.journald.extraConfig = "SystemMaxUse=500M";

  services.deluge = {
    enable = true;
    web.enable = true;
  };
}
