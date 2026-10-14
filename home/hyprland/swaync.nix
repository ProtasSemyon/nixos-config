{ ... }:

# SwayNotificationCenter — the notification daemon.
#
# Chosen over dunst because it renders inline *action buttons*. That is what
# makes Bluetooth pairing usable: blueman sends the confirmation request as a
# notification carrying "Confirm"/"Deny" actions, and dunst only exposes those
# through a context menu. swaync draws them as real buttons in the popup.
#
# It also gives us a notification center (history + do-not-disturb) and MPRIS
# media controls, all themeable via GTK CSS — styled below to match the waybar
# "forest green" palette (see dotfiles/waybar/style.css).
{
  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "user";

      control-center-margin-top = 10;
      control-center-margin-bottom = 10;
      control-center-margin-right = 10;
      control-center-margin-left = 10;
      control-center-width = 400;
      control-center-height = 900;

      notification-window-width = 400;
      notification-icon-size = 52;
      notification-body-image-height = 120;
      notification-body-image-width = 220;
      notification-2fa-action = true;
      notification-inline-replies = true;

      timeout = 8;
      timeout-low = 4;
      timeout-critical = 0;

      fit-to-screen = true;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;

      widgets = [
        "title"
        "dnd"
        "mpris"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Уведомления";
          clear-all-button = true;
          button-text = "Очистить всё";
        };
        dnd = {
          text = "Не беспокоить";
        };
        mpris = {
          image-size = 96;
          image-radius = 12;
        };
      };
    };

    style = ''
      /* ── Forest-green palette (mirrors waybar) ───────────────────────── */
      @define-color bg          rgba(16, 40, 31, 0.94);   /* deep forest   */
      @define-color bg-solid    #10281F;
      @define-color surface     #1C3A2B;                  /* lighter green */
      @define-color surface-hi  #244a37;
      @define-color text        #CDE8BE;                  /* soft leaf     */
      @define-color muted       #7A8B82;                  /* mist gray     */
      @define-color emerald     #2FBF71;                  /* accent        */
      @define-color sun         #F8E58C;                  /* warm yellow   */
      @define-color rose        #E58EB2;                  /* urgent/critical */
      @define-color sky         #75D6FF;

      * {
        font-family: "FiraCode Nerd Font Mono", FiraCode, sans-serif;
        font-size: 14px;
      }

      /* ── Popup notifications (floating) ──────────────────────────────── */
      .notification-row {
        outline: none;
        margin: 0;
        padding: 0;
      }

      .notification {
        margin: 8px 10px 0 10px;
        padding: 0;
        border-radius: 14px;
        border: 1px solid alpha(@emerald, 0.35);
        background: @bg;
        box-shadow: 0 6px 18px rgba(0, 0, 0, 0.45);
      }

      .floating-notifications .notification {
        margin: 10px;
      }

      .notification.critical {
        border-color: @rose;
        box-shadow: 0 0 0 1px @rose, 0 6px 18px rgba(0, 0, 0, 0.5);
      }
      .notification.low {
        border-color: alpha(@muted, 0.4);
      }

      .notification-content {
        padding: 12px 14px;
        border-radius: 14px;
      }

      .notification-default-action,
      .notification-action {
        color: @text;
        background: transparent;
        border: none;
        box-shadow: none;
      }
      .notification-default-action {
        border-radius: 14px;
      }
      .notification-default-action:hover {
        background: @surface-hi;
      }

      .summary {
        color: @text;
        font-weight: bold;
        font-size: 15px;
      }
      .time {
        color: @muted;
        font-size: 12px;
      }
      .body {
        color: alpha(@text, 0.92);
        font-size: 13px;
      }
      .body-image {
        margin-top: 8px;
        border-radius: 10px;
      }

      /* App icon badge */
      .notification-content .app-icon {
        margin: 0 8px 0 2px;
      }

      /* ── Action buttons (this is what makes BT pairing clickable) ─────── */
      .notification-action {
        margin: 8px 6px 2px 6px;
        padding: 8px 10px;
        border-radius: 10px;
        background: @surface;
        color: @text;
        border: 1px solid alpha(@emerald, 0.3);
        font-weight: bold;
      }
      .notification-action:hover {
        background: @emerald;
        color: @bg-solid;
        border-color: @emerald;
      }
      .notification-action:active {
        background: @sun;
        color: @bg-solid;
      }
      /* First action = the "primary"/accept one → highlight it */
      .notification-action:first-child {
        background: alpha(@emerald, 0.25);
      }

      /* Inline reply box */
      .notification .inline-reply {
        margin-top: 8px;
      }
      .notification .inline-reply-entry {
        background: @bg-solid;
        color: @text;
        border-radius: 8px;
        border: 1px solid @surface-hi;
      }
      .notification .inline-reply-button {
        margin-left: 6px;
        background: @surface;
        color: @text;
        border-radius: 8px;
        border: 1px solid alpha(@emerald, 0.3);
      }
      .notification .inline-reply-button:hover {
        background: @emerald;
        color: @bg-solid;
      }

      /* Close button */
      .close-button {
        background: transparent;
        color: @muted;
        border-radius: 100%;
        margin: 8px 8px 0 0;
        padding: 2px;
        min-width: 22px;
        min-height: 22px;
      }
      .close-button:hover {
        background: @rose;
        color: @bg-solid;
      }

      /* Progress bar (e.g. volume/brightness OSD-like notifications) */
      progressbar,
      progressbar trough,
      progressbar progress {
        border-radius: 10px;
      }
      progressbar progress {
        background: @emerald;
      }
      progressbar trough {
        background: @surface;
      }

      /* ── Control center ──────────────────────────────────────────────── */
      .control-center {
        background: @bg;
        border-radius: 18px;
        border: 1px solid alpha(@emerald, 0.3);
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
        margin: 0;
        padding: 14px;
      }

      .control-center .notification {
        margin: 8px 0 0 0;
      }

      .control-center-list {
        background: transparent;
      }
      .control-center-list-placeholder {
        color: @muted;
        opacity: 0.6;
      }

      /* Title widget + clear-all button */
      .widget-title {
        color: @text;
        font-size: 16px;
        font-weight: bold;
        margin: 4px 4px 10px 4px;
      }
      .widget-title > button {
        background: @surface;
        color: @text;
        border-radius: 10px;
        border: 1px solid alpha(@emerald, 0.3);
        padding: 4px 12px;
        font-size: 13px;
      }
      .widget-title > button:hover {
        background: @rose;
        color: @bg-solid;
        border-color: @rose;
      }

      /* Do-not-disturb toggle */
      .widget-dnd {
        color: @text;
        margin: 4px;
        font-size: 14px;
      }
      .widget-dnd > switch {
        background: @surface;
        border-radius: 100px;
        border: 1px solid alpha(@emerald, 0.3);
      }
      .widget-dnd > switch:checked {
        background: @emerald;
      }
      .widget-dnd > switch slider {
        background: @text;
        border-radius: 100px;
      }

      /* MPRIS media widget */
      .widget-mpris {
        color: @text;
        margin: 6px 2px;
      }
      .widget-mpris-player {
        background: @surface;
        border-radius: 14px;
        padding: 10px;
      }
      .widget-mpris-title {
        font-weight: bold;
        font-size: 14px;
      }
      .widget-mpris-subtitle {
        color: @muted;
        font-size: 12px;
      }
      .widget-mpris button {
        background: transparent;
        color: @text;
        border-radius: 100%;
      }
      .widget-mpris button:hover {
        background: @emerald;
        color: @bg-solid;
      }
    '';
  };
}
