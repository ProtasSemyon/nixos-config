{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      # Over Tailscale (MagicDNS), so it works from anywhere, not only from the
      # office LAN where the address is a DHCP lease. Host key is pinned in
      # modules/nixos/services.nix.
      "office" = {
        hostname = "office.tail883758.ts.net";
        user = "smn";
        identityFile = "~/.ssh/home-laptop";
        identitiesOnly = true;
      };
      # The two laptops, by the hostnames the router hands out.
      "saymoon fx505dd" = {
        identityFile = "~/.ssh/home-laptop";
        identitiesOnly = true;
      };
      # Личный аккаунт ProtasSemyon — дефолт для git@github.com:...
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
      # Рабочий аккаунт — клонировать как git@github-work:<org>/<repo>.git
      "github-work" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_work";
        identitiesOnly = true;
      };
    };
  };
}
