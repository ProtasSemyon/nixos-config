{ inputs, ... }:

# Zen, declared so that every machine gets the same browser: extensions,
# containers, search and the prefs that matter.
#
# Spaces and pinned tabs are deliberately NOT here. This repository is public,
# and the pins are internal work URLs and personal links; Zen's own sync
# (Settings > Sync, through the Mozilla account) carries them instead.
#
# Also per machine, in the profile itself: cookies and logins, history,
# extension data (1Password vault, Authenticator secrets, ZeroOmega profiles),
# open tabs.
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;

    # Extensions come from AMO by id and update themselves there. normal
    # rather than force: they can still be disabled per machine.
    policies = {
      DisableAppUpdate = true;
      ExtensionSettings =
        builtins.mapAttrs
          (id: _: {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";
            installation_mode = "normal_installed";
          })
          {
            "uBlock0@raymondhill.net" = "uBlock Origin";
            "{d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}" = "Adblock Plus";
            "{d634138d-c276-4fc8-924b-40a0ea21d284}" = "1Password";
            "authenticator@mymindstorm" = "Authenticator";
            "suziwen1@gmail.com" = "ZeroOmega";
            "browser@tunnelbear.com" = "TunnelBear VPN";
            "Shortkeys@Shortkeys.com" = "Shortkeys";
            "{8d9dd0f0-6dc5-4595-8c81-fab876d0fef0}" = "CORS Unblock";
            "myallychou@gmail.com" = "Unhook";
            "{e5b6e4ac-ec96-44f5-b257-e4d3c8291b41}" = "Linguist";
            "console-wallet@consolewallet.io" = "Console Wallet";
            "click-and-clean@freebusinessapps" = "Super History & Cache Cleaner";
          };
    };

    profiles.default = {
      id = 0;
      isDefault = true;
      name = "Default Profile";
      path = "default";

      search = {
        force = true;
        default = "ddg";
      };

      # Ids matter: synced spaces refer to containers by number (the work
      # space uses 2).
      containersForce = true;
      containers = {
        Personal = {
          id = 1;
          icon = "fingerprint";
          color = "blue";
        };
        Work = {
          id = 2;
          icon = "briefcase";
          color = "orange";
        };
        Banking = {
          id = 3;
          icon = "dollar";
          color = "green";
        };
        Shopping = {
          id = 4;
          icon = "cart";
          color = "pink";
        };
        PixelPlex = {
          id = 6;
          icon = "chill";
          color = "blue";
        };
      };

      # Written to user.js, so they are reapplied on every start: changing one
      # in about:config lasts until Zen is restarted.
      settings = {
        # Layout: sidebar collapsed to icons, separate toolbar, no compact mode.
        "zen.view.sidebar-expanded" = false;
        "zen.view.compact.enable-at-startup" = false;
        "zen.view.use-single-toolbar" = false;
        "zen.view.window.scheme" = 0;
        "zen.workspaces.separate-essentials" = false;
        "zen.site-data-panel.show-callout" = false;
        "zen.swipe.is-fast-swipe" = false;
        "layout.css.prefers-color-scheme.content-override" = 0;
        "widget.wayland.opaque-region.enabled" = false;

        "general.autoScroll" = true;
        "browser.ctrlTab.sortByRecentlyUsed" = true;
        "font.name.serif.x-western" = "FiraCode Nerd Font";
        "browser.search.region" = "BY";

        # Hardware video decoding through VA-API (AMD and Intel alike).
        "media.ffmpeg.vaapi.enabled" = true;
        "media.ffvpx.enabled" = false;
        "media.hardware-video-decoding.force-enabled" = true;

        # DNS over HTTPS off: the system resolver (resolved, plus the VPNs'
        # split DNS) must see the queries.
        "network.trr.mode" = 5;

        # Keep everything across restarts.
        "privacy.history.custom" = true;
        "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = false;
        "privacy.clearOnShutdown_v2.cache" = false;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
        "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
      };
    };
  };
}
