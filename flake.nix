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
      defaultUsername = "smn";
      pkgs = nixpkgs.legacyPackages.${system};

      # Flake-level modules every host gets, regardless of the machine.
      commonModules = [
        inputs.home-manager.nixosModules.default
        inputs.nix-index-database.nixosModules.nix-index
        inputs.distro-grub-themes.nixosModules.${system}.default
        inputs.sops-nix.nixosModules.sops
      ];

      # Adding a machine: create hosts/<dir>/ (default.nix +
      # hardware-configuration.nix, optionally home.nix) and add one entry to
      # nixosConfigurations below. `modules` is for the extra flake inputs that
      # machine needs — a nixos-hardware profile, for instance.
      mkHost =
        {
          host,
          username ? defaultUsername,
          modules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs self username; };
          modules = commonModules ++ [ host ] ++ modules;
        };
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

      nixosConfigurations.saymoon = mkHost {
        host = ./hosts/lenovo-ideapad;
        modules = [ inputs.nixos-hardware.nixosModules.lenovo-ideapad-slim-5 ];
      };

      # ASUS TUF Gaming FX505DD — Ryzen (Picasso) + Vega 8 iGPU + GTX 1050.
      # nixos-hardware has no profile for this model, so the closest generic
      # ones are composed by hand. common-gpu-nvidia is the PRIME *offload*
      # module (prime.nix), which is what a muxless Optimus machine wants.
      nixosConfigurations.fx505dd = mkHost {
        host = ./hosts/asus-fx505dd;
        modules = with inputs.nixos-hardware.nixosModules; [
          common-cpu-amd
          common-pc-laptop
          common-pc-ssd
          common-gpu-nvidia
          asus-battery
        ];
      };
    };
}
