{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "office" = {
        hostname = "192.168.5.2";
        user = "smn";
        identityFile = "~/.ssh/home-laptop";
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
