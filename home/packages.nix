{ pkgs, self, ... }:

{
  home.packages = with pkgs; [
    libreoffice
    fastfetch
    telegram-desktop
    discord
    vlc
    sioyek

    yandex-music # tray support is built in since the package was rewritten

    prismlauncher
    xclicker

    self.packages.${stdenv.hostPlatform.system}.neovim

    dbeaver-bin

    insomnia
    postman

    zed-editor

    obsidian
    libsecret # secret-tool: read KeePassXC entries over Secret Service (Insomnia plugin)
  ];
}
