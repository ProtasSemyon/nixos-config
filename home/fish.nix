{ ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
    shellAliases = {
      # nh reads the flake from programs.nh.flake; it elevates privileges itself.
      # Pull first: the lock nrsu pushed from another machine is what gets
      # built, and the build cache on office already has its results.
      nrs = "git -C ~/nixos-config pull --ff-only --quiet; and nh os switch";
      # nrsu is a script now (home/nrsu.nix): update, switch, commit and push
      # flake.lock, sync the project devshells.
    };
  };
}
