{ username, ... }:

# System half of the alarm clock in home/alarm.nix.
#
# The ringing process runs under the user manager, outside any logind session,
# so polkit judges it by `allow_any`: "no" for the lid-switch inhibitor and
# auth_admin for the sleep one. Without them a laptop woken with the lid shut
# is put back to sleep by logind about 30 s after resume, mid-ring. This only
# lets the user *hold* those inhibitors; it grants nothing else.
{
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if ((action.id == "org.freedesktop.login1.inhibit-handle-lid-switch" ||
           action.id == "org.freedesktop.login1.inhibit-block-sleep") &&
          subject.user == "${username}") {
        return polkit.Result.YES;
      }
    });
  '';
}
