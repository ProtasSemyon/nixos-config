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
  };

  users.groups.netdev = { };
  users.users.pulse = {
    isSystemUser = true;
    group = "pulse";
  };
  users.groups.pulse = { };
}
