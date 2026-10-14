# nixos-config

Flake-based NixOS configuration.

## Hosts

| Host         | Hostname  | Machine                                   |
| ------------ | --------- | ----------------------------------------- |
| `lenovo-ideapad` | `saymoon` | Lenovo IdeaPad Slim 5 (AMD Ryzen 7 7735HS) |
| `asus-fx505dd`   | `fx505dd` | ASUS TUF Gaming FX505DD (Picasso + GTX 1050) |

## Layout

```
flake.nix              Inputs + outputs; `mkHost` and the default username.
hosts/<host>/          Per-host entry points.
  default.nix            Host-specific config + Home Manager wiring.
  home.nix               Host-specific Home Manager config (monitors, kanshi).
  hardware-configuration.nix
  edid/                  Forced EDID for the internal panel.
modules/nixos/         System (NixOS) modules. default.nix imports the common set.
                         Optional modules (amd.nix, godot.nix,
                         ciscoPacketTracer.nix, kde.nix) are imported per-host
                         as needed.
home/                  Home Manager modules (pure HM). default.nix imports them.
pkgs/                  Standalone package definitions.
nvf/                   Neovim (nvf) configuration, exposed as packages.neovim.
dotfiles/              Non-Nix dotfiles consumed via the `dotfiles` flake input.
```

A NixOS module configures the system; a Home Manager module configures the
user environment. They are kept separate — system-level pieces of a desktop
feature live under `modules/nixos/` and the user-level pieces under `home/`.

Nothing under `modules/` or `home/` may hardcode a fact about one machine.
Anything that is true of a particular laptop — disk UUIDs, panel geometry,
monitor serials, GPU index, RAM-dependent build limits, vendor quirks — belongs
in `hosts/<host>/`, either directly or through the options those modules
declare (`host.display.internal`, `hyprland.monitors`).

## Adding a machine

1. `cp -r hosts/lenovo-ideapad hosts/<new>` and drop what does not apply
   (`edid/` is specific to this panel).
2. Replace `hardware-configuration.nix` with the one `nixos-generate-config`
   produces on the new machine, and update `networking.hostName`,
   `fileSystems."/"` options, `swapDevices` and `nix.settings.max-jobs`.
3. Set `host.display.internal` (panel name, mode, scale, refresh rates, and
   `acDevice` if the firmware does not call the adapter `ACAD`), plus the
   `services.tlp.settings` that depend on the chassis.
4. In `hosts/<new>/home.nix`, set `hyprland.monitors` and the kanshi profiles
   for that machine's displays.
5. Import the vendor module the machine needs (`../../modules/nixos/amd.nix`),
   and register the host in `flake.nix` via `mkHost`.
6. Add the new machine's host key to `.sops.yaml` and run
   `sops updatekeys secrets/secrets.yaml`, otherwise activation cannot decrypt
   the SSH keys. The key is derived from `/etc/ssh/ssh_host_ed25519_key`, so
   either generate that key before `nixos-install` (`ssh-keygen -t ed25519 -N ""
   -f /mnt/etc/ssh/ssh_host_ed25519_key`, then `ssh-to-age -i <pubkey>`), or
   install with `secrets.nix` temporarily removed and add the key afterwards.

### Partitioning

A machine that owns its disk takes the obvious layout: a FAT32 ESP labelled
`BOOT` mounted at `/boot`, and a btrfs root labelled `nixos`.

`fx505dd` dual-boots Windows across two SSDs — a 128 GB one holding Windows
and its ESP, and a 1 TB one split between a Windows data partition and free
space. NixOS goes entirely on the second disk, *including its own ESP*, so the
Windows disk is never written to and reinstalling either OS cannot break the
other. Two ESPs on one machine is normal; the firmware simply lists a boot
entry per disk.

```sh
# Before leaving Windows: turn off Fast Startup and hibernation (`powercfg /h
# off`) so the NTFS volumes are left clean, and disable Secure Boot in the UEFI
# setup — the proprietary NVIDIA module is unsigned and will not load with it on.

# In the unallocated space of the 1 TB SSD, create two partitions:
#   2 GiB, type "EFI System"
#   the rest, type "Linux filesystem"
# Leave the 128 GB disk alone.
cfdisk /dev/<the 1 TB disk>

mkfs.fat -F32 -n NIXBOOT /dev/<esp partition>
mkfs.btrfs    -L nixos   /dev/<root partition>

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot && mount /dev/disk/by-label/NIXBOOT /mnt/boot
```

Then `nixos-generate-config --root /mnt`, copy the result into `hosts/<new>/`,
and `nixos-install --flake /mnt/etc/nixos#<new>`. The Windows entry comes from
os-prober, which runs during the install and finds the bootloader on the other
disk.
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
