{ pkgs, self, ... }:

{
  home.packages = with pkgs; [
    libreoffice
    fastfetch
    neohtop
    telegram-desktop
    discord
    logseq
    vlc

    (yandex-music.override {
      trayEnabled = true; # Whether to enable tray support
      electronArguments = ""; # Extra arguments to electron executable
    })

    prismlauncher
    xclicker

    self.packages.${stdenv.hostPlatform.system}.neovim

    dbeaver-bin

    insomnia
    postman

    grok-cli

    zed-editor
    jetbrains-toolbox

    obsidian

    wineWow64Packages.waylandFull
  ];
}
