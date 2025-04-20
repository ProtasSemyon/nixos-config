{pkgs, ...}: 
{
  config.vim = {
    theme = {
      enable = true;
      name = "dracula";
      style = "dark";
    };

    statusline.lualine.enable = true;
    telescope.enable = true;
    autocomplete.nvim-cmp.enable = true;
  };
}