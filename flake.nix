{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    distro-grub-themes.url = "github:AdisonCavani/distro-grub-themes";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-guiutils.url = "github:hyprwm/hyprland-guiutils";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nvf,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      username = "smn";
      pkgs = nixpkgs.legacyPackages.${system};
      specialArgs = { inherit inputs self username; };
    in
    {
      formatter.${system} = pkgs.nixfmt;

      packages.${system}.neovim =
        (nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [ ./nvf ];
        }).neovim;

      # `nix flake check` runs these linters over the whole tree.
      checks.${system} = {
        statix = pkgs.runCommand "statix-check" { } ''
          ${pkgs.statix}/bin/statix check -c ${self}/statix.toml ${self}
          touch $out
        '';
        deadnix = pkgs.runCommand "deadnix-check" { } ''
          ${pkgs.deadnix}/bin/deadnix --fail ${self}
          touch $out
        '';
      };

      nixosConfigurations.saymoon = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/lenovo-ideapad
          inputs.home-manager.nixosModules.default
          inputs.nixos-hardware.nixosModules.lenovo-ideapad-slim-5
          inputs.nix-index-database.nixosModules.nix-index
          inputs.distro-grub-themes.nixosModules.${system}.default
          inputs.sops-nix.nixosModules.sops
        ];
      };
    };
}
