{ ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
    shellAliases = {
      # nh reads the flake from programs.nh.flake; it elevates privileges itself.
      nrs = "nh os switch";
      nrsu = "nh os switch --update"; # update flake inputs, then switch
    };
  };
}
