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
      # Update flake inputs and switch, then move the project devshells to the
      # new nixpkgs (home/dev-envs.nix).
      nrsu = "nh os switch --update; and dev-envs-sync";
    };
  };
}
