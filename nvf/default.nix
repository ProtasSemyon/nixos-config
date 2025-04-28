{pkgs, ...}: 
{
  # vim = {
  #   theme = {
  #     enable = true;
  #     name = "dracula";
  #     style = "dark";
  #   };

  #   statusline.lualine.enable = true;
  #   telescope.enable = true;
  #   autocomplete.nvim-cmp.enable = true;

  #   languages = {
  #     enableLSP = true;
  #     enableTreesitter = true;

  #     nix.enable = true;
  #     ts.enable = true;
  #     rust.enable = true;
  #   };

  # };

  vim = {
    additionalRuntimePaths = [
      ./nvim
    ];

    luaConfigRC.GenesisNvim = /* lua */ ''
      require("GenesisNvim")
    '';
  };
}