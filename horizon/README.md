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
place before the first launch, the client showed data sharing as off.
