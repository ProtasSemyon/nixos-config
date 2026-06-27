# nixos-config

Flake-based NixOS configuration.

## Hosts

| Host         | Hostname  | Machine                                   |
| ------------ | --------- | ----------------------------------------- |
| `lenovo-ideapad` | `saymoon` | Lenovo IdeaPad Slim 5 (AMD Ryzen 7 7735HS) |

## Layout

```
flake.nix              Inputs + outputs; defines `username` and specialArgs.
hosts/<host>/          Per-host entry points.
  default.nix            Host-specific config + Home Manager wiring.
  hardware-configuration.nix
  edid/                  Forced EDID for the internal panel.
modules/nixos/         System (NixOS) modules. default.nix imports the common set.
                         Optional modules (godot.nix, ciscoPacketTracer.nix,
                         kde.nix) are imported per-host as needed.
home/                  Home Manager modules (pure HM). default.nix imports them.
pkgs/                  Standalone package definitions.
nvf/                   Neovim (nvf) configuration, exposed as packages.neovim.
dotfiles/              Non-Nix dotfiles consumed via the `dotfiles` flake input.
```

A NixOS module configures the system; a Home Manager module configures the
user environment. They are kept separate — system-level pieces of a desktop
feature live under `modules/nixos/` and the user-level pieces under `home/`.

## Usage

```sh
# Rebuild and switch (alias: nrs)
sudo nixos-rebuild switch --flake .#saymoon

# Update inputs then rebuild (alias: nrsu)
nix flake update && sudo nixos-rebuild switch --flake .#saymoon

# Build without activating
nixos-rebuild build --flake .#saymoon

# Validate the flake
nix flake check

# Format all Nix files
nix fmt
```
