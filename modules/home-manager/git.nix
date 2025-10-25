{ ... }:

{
  home-manager.users.smn = { ... } : {
    programs.git = {
      enable = true;
      settings = {
        user.name  = "Semyon Protas";
        user.email = "semyon.protas@gmail.com";
        init.defaultBranch = "main";
        core.autocrlf = "input";
      };
    }; 

    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
      };
    };
  };
}
