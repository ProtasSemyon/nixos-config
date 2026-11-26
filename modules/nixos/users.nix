{ username, ... }:

{
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "kvm"
      "adbusers"
      "docker"
      "wireshark"
    ];
    # The sops-provided `home-laptop` key (modules/nixos/secrets.nix) is on
    # both laptops, so each can reach the other — e.g. `nix copy` a built
    # system across instead of building it twice.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLNtPo6SWduzZQvV0MYlwHHerV7OWVHinVyGXZQpHRY nixos-laptop"
    ];
  };

  users.groups.netdev = { };
  users.users.pulse = {
    isSystemUser = true;
    group = "pulse";
  };
  users.groups.pulse = { };
}
