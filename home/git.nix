{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Semyon Protas";
      user.email = "semyon.protas@gmail.com";
      init.defaultBranch = "main";
      core.autocrlf = "input";

      # Use the work email automatically for repositories under ~/work.
      includeIf."gitdir:~/work/".path = "~/.config/git/work.inc";
    };
  };

  # Per-directory override pulled in by the includeIf above.
  xdg.configFile."git/work.inc".text = ''
    [user]
        email = s.protas@pixelplex.io
  '';

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };
}
