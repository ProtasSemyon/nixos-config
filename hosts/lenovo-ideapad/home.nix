{  pkgs, inputs, system, self, ... }:

{
  home.username = "smn";
  home.homeDirectory = "/home/smn";

  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    android-studio
    libreoffice
    neofetch
    neohtop
    telegram-desktop
    webcord
    logseq
    vlc
    
    #Gaming
    (lutris.override {
      extraLibraries =  pkgs: [
        # List library dependencies here
      ];
    })

    appimage-run
    prismlauncher
    xclicker
    
    inputs.dracula-cursors.packages."${system}".default
    inputs.zen-browser.packages."${system}".default
    self.packages.${pkgs.stdenv.system}.neovim

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # (pkgs.symlinkJoin {
    #   name = "vlc";
    #   paths = [ pkgs.vlc ];
    #   buildInputs = [ pkgs.makeWrapper ];
    #   postBuild = ''
    #     wrapProgram $out/bin/vlc \
    #       --unset DISPLAY
    #     mv $out/share/applications/vlc.desktop{,.orig}
    #     substitute $out/share/applications/vlc.desktop{.orig,} \
    #       --replace-fail Exec=${pkgs.vlc}/bin/vlc Exec=$out/bin/vlc
    #   '';
    # })
    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/smn/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # EDITOR = "emacs";
  };
  
  home.pointerCursor = {
    name = "volantes_light_cursors";
    size = 24;
    package = pkgs.volantes-cursors;

    enable = true;

    x11.enable = true;
    gtk.enable = true;
    hyprcursor.enable = true;
    sway.enable = true;
  };
  
  gtk = {
    enable = true;
    theme = {
      name = "Orchis-Dark";
      package = pkgs.orchis-theme;
    };
    iconTheme.name = "Papirus-Dark";
    iconTheme.package = pkgs.catppuccin-papirus-folders.override {
      flavor = "macchiato";
      accent = "sapphire";
    };
  };
  
  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
