{pkgs, nvim-config, ...}: 
{
  vim = {
    theme = {
      enable = true;
      name = "dracula";
      style = "dark";
    };

    statusline.lualine.enable = true;
    telescope.enable = true;
    autocomplete.nvim-cmp.enable = true;

    lsp.enable = true;
    languages = {
      enableTreesitter = true;

      nix.enable = true;
      ts.enable = true;
      rust.enable = true;
    };

    lsp.lspconfig.enable = true;
    filetree.nvimTree.enable = true;
  };
}