{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    zen-browser.url = "github:ProtasSemyon/zen-browser-flake";

    logseq.url = "github:ProtasSemyon/logseq-nix-flake";

    dracula-cursors.url = "github:ProtasSemyon/dracula-cursors-nixos";

    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gc-env.url = "github:Julow/nix-gc-env";

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    distro-grub-themes.url = "github:AdisonCavani/distro-grub-themes";
  };

  outputs = { self, nixpkgs, nvf, ... }@inputs: let 
    system = "x86_64-linux"; 
  in {
    packages.${system}.neovim = 
      (nvf.lib.neovimConfiguration 
      {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          ({ config, lib, pkgs, ... }: {
            _module.args = {
              nvim-config = inputs.nvim-config;
            };
          })
          ./nvf
        ];
      })
      .neovim;

    nixosConfigurations.saymoon = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        inherit system;
        inherit self;
      };
      modules = [
        ./hosts/lenovo-ideapad/configuration.nix
        inputs.home-manager.nixosModules.default
        inputs.nixos-hardware.nixosModules.lenovo-ideapad-slim-5
        inputs.nix-gc-env.nixosModules.default
        inputs.distro-grub-themes.nixosModules.${system}.default
      ];
    };
  };
}
