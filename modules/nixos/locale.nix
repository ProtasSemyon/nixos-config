{ pkgs, ... }:

{
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    font = "ter-v32n";
    packages = [ pkgs.terminus_font ];
    keyMap = "us";
  };
}
