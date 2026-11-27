{ username, ... }:

let
  home = "/home/${username}";
in
{
  # sops-nix: secrets are encrypted in secrets/secrets.yaml (see .sops.yaml for
  # recipients) and decrypted at activation using the host SSH key.
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # On a fresh install ~/.ssh does not exist yet when the secrets below are
  # first linked, so sops-nix creates it as root:root. Home Manager then cannot
  # write ~/.ssh/config, and its whole activation fails. tmpfiles runs before
  # home-manager-<user>.service and fixes the owner of an existing directory.
  systemd.tmpfiles.rules = [ "d ${home}/.ssh 0700 ${username} users -" ];

  # Materialize the user's SSH private keys straight into ~/.ssh (owner smn,
  # mode 0600). Editing secrets: `sops secrets/secrets.yaml` (uses the personal
  # age key at ~/.config/sops/age/keys.txt).
  sops.secrets =
    let
      sshKey = name: {
        owner = username;
        mode = "0600";
        path = "${home}/.ssh/${name}";
      };
    in
    {
      "id_ed25519" = sshKey "id_ed25519";
      "id_ed25519_work" = sshKey "id_ed25519_work";
      "home-laptop" = sshKey "home-laptop";
    };
}
