# Working in this repository

Flake-based NixOS configuration for two laptops. `README.md` has the layout and
the install procedure; this file is the part that is specific to working on it.

| Host | Hostname | Machine |
| --- | --- | --- |
| `lenovo-ideapad` | `saymoon` | Lenovo IdeaPad Slim 5, Ryzen 7 7735HS + Radeon 680M |
| `asus-fx505dd` | `fx505dd` | ASUS TUF FX505DD, Ryzen Picasso + Vega 8 + GTX 1050, dual-boots Windows |

## The one hard rule

**Nothing under `modules/` or `home/` may hardcode a fact about one machine.**
Disk UUIDs, panel geometry, monitor serials, GPU bus IDs or card indices,
RAM-dependent build limits, vendor quirks and chassis-specific firmware knobs
belong in `hosts/<host>/`, either set directly or through the options the shared
modules declare:

- `host.display.internal` — built-in panel: `output`, `mode`, `scale`,
  `refreshRate.{ac,battery}`, `acDevice`. Declared in
  `modules/nixos/display-refresh.nix`, which generates the `edp-refresh` script
  from it. A host without a built-in panel leaves `output` at `null`; the
  command still exists and exits 0, because the Hyprland autostart and the
  kanshi profiles call it unconditionally.
- `hyprland.monitors` (Home Manager) — declared in `home/hyprland/default.nix`,
  generates the `hl.monitor({...})` calls prepended to the shared
  `hyprland.lua`. Hosts set it from their own `hosts/<host>/home.nix`, which
  also carries the kanshi profiles.

Vendor-wide but machine-independent pieces go in their own optional module that
hosts import — see `modules/nixos/amd.nix`. Per-host modules are wired in
`flake.nix` through `mkHost`.

If you find yourself adding a conditional on the hostname inside a shared
module, that is the signal to add an option instead.

## Verifying a change

Always run these before claiming a change works. The second one matters most:
if a refactor is supposed to be behaviour-preserving, prove it rather than
assume it.

```sh
# Lints (statix + deadnix). Both are wired as flake checks.
nix flake check

# Does the system still evaluate, and is the derivation unchanged?
nix eval --raw .#nixosConfigurations.saymoon.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.fx505dd.config.system.build.toplevel.drvPath

# Does it actually build?
nix build --no-link --print-out-paths \
  .#nixosConfigurations.<host>.config.system.build.toplevel

# Compare specific resolved values instead of guessing what merged into what:
nix eval --json --impure --expr '
  let c = (builtins.getFlake (toString ./.)).nixosConfigurations.<host>.config;
  in { x = c.some.option; }'
```

Formatting: `nix fmt .` — note the trailing dot. Bare `nix fmt` fails with
`unexpected end of input`, because `formatter` is plain `pkgs.nixfmt`, which
reads stdin when given no paths.

**New files must be `git add`ed before any of the above will see them.** A flake
only reads files tracked by git, and an untracked file fails with a message
about making it visible to Nix.

## Rebuilding

```fish
nrs   # nh os switch
nrsu  # nh os switch --update
```

`nh` takes the flake path from `programs.nh.flake` (`~/nixos-config`, set in
`modules/nixos/nh.nix`) and picks the configuration by hostname, so the same
aliases work unchanged on both machines. The repository is expected to live at
`~/nixos-config`.

## Secrets

sops-nix. `secrets/secrets.yaml` holds the user's SSH keys and is decrypted at
activation with the host key derived from `/etc/ssh/ssh_host_ed25519_key`;
`.sops.yaml` lists the recipients. Editing needs the personal age key at
`~/.config/sops/age/keys.txt`:

```sh
sops secrets/secrets.yaml
```

A new machine's host key must be added to `.sops.yaml` followed by
`sops updatekeys secrets/secrets.yaml`, or activation cannot decrypt anything.

## Pushing

`origin` is `https://github.com/ProtasSemyon/nixos-config`, but **https pushes do
not work**: `home/git.nix` sets `programs.gh.settings.git_protocol = "ssh"`, so
`gh auth git-credential` refuses to serve https credentials. Push over SSH,
which authenticates as `ProtasSemyon` using the sops-provided key:

```sh
git -c 'url.git@github.com:.insteadOf=https://github.com/' push origin main
```

On `saymoon` there is additionally a stale, unmanaged `~/.gitconfig` left over
from an old `gh auth setup-git`. It resets the credential helper list and points
at a `gh` store path that no longer exists, shadowing the correct helper in the
home-manager-managed `~/.config/git/config`. Deleting that file is safe.

## Pending: finish the fx505dd tuning

**Only do this on `fx505dd`** (check with `hostname`). It was installed with
values that could not be known before the machine existed. Each is harmless
while wrong — nothing here blocks booting — but all should be corrected on the
first pass. Run the commands, edit `hosts/asus-fx505dd/{default,home}.nix`,
`nrs`, then delete this section.

### 1. PRIME bus IDs

`lspci` prints hex, NixOS wants decimal — on `saymoon` the GPU at `0000:73:00.0`
is `PCI:115:0:0`, not `PCI:73:0:0`. Do not convert by hand:

```sh
lspci -D | grep -E 'VGA|3D' | awk '{print $1}' | while read -r a; do
  rest=${a#*:}; bus=${rest%%:*}; df=${rest#*:}; dev=${df%%.*}; fn=${df#*.}
  printf '%s  ->  PCI:%d:%d:%d\n' "$a" 0x$bus 0x$dev 0x$fn
done
```

The `VGA ... AMD` line is `hardware.nvidia.prime.amdgpuBusId`, the
`3D ... NVIDIA` line is `nvidiaBusId`. Currently placeholders.

### 2. Mains adapter name

```sh
for d in /sys/class/power_supply/*; do printf '%s = %s\n' "$(basename $d)" "$(cat $d/type 2>/dev/null)"; done
```

The entry of type `Mains` is `host.display.internal.acDevice`. Currently
guessed as `ADP0`. If it is wrong the refresh script just assumes AC.

### 3. Panel output, resolution and refresh rate

```sh
ls /sys/class/drm/                                  # connector name, e.g. card1-eDP-1
hyprctl monitors                                    # live mode and scale
nix shell nixpkgs#edid-decode -c sh -c \
  'edid-decode < /sys/class/drm/card*-eDP-1/edid' | grep -iE 'DTD|Monitor ranges'
```

`/sys/class/drm/*/modes` lists resolutions only, with one duplicate line per
refresh rate, so it cannot tell 60 Hz from 120 Hz — use the EDID. `DTD 1` is the
native mode, `Monitor ranges` the supported span.

Feeds `host.display.internal.{output,mode,refreshRate.ac}` and, in
`hosts/asus-fx505dd/home.nix`, `hyprland.monitors` and the kanshi profile.
Currently assumed 1920x1080 @ 60.

### 4. Windows data partition

`hosts/asus-fx505dd/hardware-configuration.nix` carries a commented-out
`fileSystems."/mnt/data"` block for the NTFS partition on the 1 TB SSD. Fill in
the label from `lsblk -o NAME,SIZE,FSTYPE,LABEL` and uncomment.

### 5. gamemode GPU

`modules/nixos/gaming.nix` deliberately leaves `programs.gamemode.settings.gpu`
unset, because the card index is ambiguous on a hybrid machine. If it is worth
setting, `ls /sys/class/drm` gives the indices and it belongs in the host file.

## Verify after the above

```sh
cat /sys/module/rtw88_pci/parameters/disable_aspm   # expect Y -- the RTL8821CE workaround
nvidia-smi                                          # dGPU visible
nvidia-offload glxinfo | grep 'OpenGL renderer'     # offload reaches the GTX 1050
efibootmgr -v                                       # one NVRAM entry per disk
grep -i -A6 microsoft /boot/grub/grub.cfg           # os-prober found Windows
```

If the Windows entry is missing, that is expected when Windows was installed
after NixOS: os-prober runs at rebuild time, not at boot. Another `nrs` fixes
it. Independently of GRUB, each OS has its own ESP on its own disk and its own
UEFI boot entry, so the firmware boot menu always works as a fallback.
