# Omnissa Horizon Client

The AUR package `omnissa-horizon-client` works unmodified. Last used: 2609-1,
maintainer eworm, Oct 2026. It downloads Omnissa's official tarball from
`download3.omnissa.com` and checks it against a pinned SHA-256.

Install only the main package. The same build produces optional extras that aren't
needed here: `-client-next` (tech preview), `-html5mmr` (HTML5 video offload,
which needs agent-side support), `-usb`, `-integrated-printing`, `-scanner-client`,
`-serialport-client` and `-file-association`.

Dependencies come from the official repos: `resvg oxipng` to build, and
`fuse2 libxml2-legacy libsigc++` among others to run.

## `view-localhost`

The client expects `view-localhost` to resolve to 127.0.0.2. The package provides
it as a systemd-resolved static record. That works when `systemd-resolved` is
active and `/etc/nsswitch.conf` has `resolve` in its `hosts:` line, which is the
case on CachyOS. Check with `getent hosts view-localhost`.

## Unreadable dialogs with a dark KDE theme

On KDE Plasma with a dark color scheme, Horizon's dialogs and status text show
light text on a white background (for example "Authenticating…" or "A network error
occurred"). Horizon draws some backgrounds white itself, but KDE writes the dark
colors into `~/.config/gtk-3.0/colors.css`, which every GTK app loads.
`GTK_THEME=Breeze:light` alone doesn't fix it, because that file overrides the
theme.

[`horizon-light`](horizon-light) launches Horizon with its own copy of
`~/.config`. Everything in it links to your real config except `gtk-3.0`, which
gets a plain light Breeze setup. Horizon's own settings (`~/.omnissa`,
`~/.config/omnissa-<user>`) are unaffected, and the rest of the desktop stays dark.
The link folder lives in `~/.local/share/horizon-light-config` and is refreshed on
every launch.

Install it for your user:

```sh
install -Dm755 horizon/horizon-light ~/.local/bin/horizon-light
sed -E "s|^Exec=horizon-client|Exec=$HOME/.local/bin/horizon-light|" \
  /usr/share/applications/horizon.client.desktop \
  > ~/.local/share/applications/horizon.client.desktop
kbuildsycoca6
```

The copied launcher has the same name as the package's one, so it takes
precedence, including for `vmware-view://` links from the browser. Quit Horizon
completely (including from the tray) and start it again.

The package's launcher file isn't modified, so upgrades don't undo this. However,
the copied launcher won't pick up upstream changes. After a Horizon upgrade, run
`diff` against `/usr/share/applications/horizon.client.desktop` and redo the `sed`
step if anything besides `Exec=` changed. To undo it, delete
`~/.local/bin/horizon-light`, `~/.local/share/applications/horizon.client.desktop`
and `~/.local/share/horizon-light-config`.

Verified on 2609-1 with Plasma 6 and Breeze Dark at 150% scale (Nov 2026). This
isn't needed with a light color scheme or on GNOME.

## Telemetry (data sharing)

Turning it off in the client's settings saves this to
`~/.omnissa/horizon-preferences`:

```
view.enableDataSharing = 'FALSE'
```

The client also reads system-wide files. Their names come from strings in the
binaries: `/etc/omnissa/horizon-default-config` (a default the user can change)
and `/etc/omnissa/horizon-mandatory-config` (locked). To turn data sharing off
before the first launch:

```
view.enableDataSharing = "FALSE"
```

in `/etc/omnissa/horizon-mandatory-config`.

**Verified** (2609-1, Nov 2026): with `/etc/omnissa/horizon-mandatory-config` in
place before the first launch, the client showed data sharing as off. Confirmed
again on 2609-1 with Omarchy (Hyprland), 17 Nov 2026: Data Sharing was unchecked in
the client's settings on first launch, and again on another Omarchy install on
19 Nov 2026 (2609-1). `~/.omnissa/horizon-preferences` has no
`view.enableDataSharing` entry in this case, so check the settings window, not that
file.

## Folders the client creates

Besides `~/.omnissa`, the client creates `~/omnissa-<user>` (with `bcr`,
`html5mmr`, `mmr` and `teamsopt` folders) when a desktop session starts. It writes
per-session config files for its redirection features there. This is expected and
not a leftover from the build.

## Other Arch-based distros

The steps above also work unchanged on Omarchy (Hyprland). The dark KDE theme fix
doesn't apply there. With a fractional monitor scale, run `omarchy/vdi-scaling`;
see "Omarchy: display scaling" in the [main README](../README.md). On a fresh Omarchy install from offline media, pacman may have
no `core`/`extra`/`multilib` databases yet (`/var/lib/pacman/sync` holds only
`offline.db` and `omarchy.db`). Run `sudo pacman -Syu` before installing the
dependencies.
