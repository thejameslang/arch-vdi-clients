# arch-vdi-clients

Notes and package recipes for installing two VDI clients on Arch-based distros
(set up on CachyOS, Nov 2026):

| Client | Source | Customised? |
|---|---|---|
| Omnissa Horizon Client | AUR `omnissa-horizon-client` | No, used as-is. Telemetry is turned off by config. See [horizon/](horizon/) |
| Citrix Workspace app | AUR `icaclient` | **Yes**. The recipe is in [citrix/icaclient/](citrix/icaclient/) |

Everything gets built in a temporary directory under `/tmp`, so nothing is left in
your home folder. The packages are installed with pacman, so they can be removed
cleanly with `pacman -R`.

If you use Claude Code, open it in this repo and ask it to set up the clients.
[CLAUDE.md](CLAUDE.md) has the step-by-step instructions it follows.

## Citrix: what's customised

Starting from the AUR `icaclient` package (base commit `77eafb5`, 26.04.10.1):

1. **Version bump to 26.08.0.225.** The AUR package was out of date. Its download
   only works for the version currently listed on Citrix's download page. The
   checksum used is the SHA-256 that **Citrix publishes** on that page.
2. **NetScaler Gateway Endpoint Analysis (EPA)**, installed to
   `/opt/Citrix/Browser-EPA`. It's what runs when a gateway asks for a device check
   (`nsgcepa://` links).
   - Arch's gpgme 2.x has a different library name than the one EPA expects. All
     the gpgme functions EPA uses exist in it with matching version tags, so EPA
     reaches it through a private compatibility link and a `/usr/bin/nsgcepa`
     wrapper. Nothing goes into `/usr/lib` or `/usr/local`.
   - The EPA binaries are unmodified. Their SHA-256s match `epaHash` and
     `epalibHash` in Citrix's `version.json`.
   - Not installed: Citrix's `startnsgcepa.sh`. It runs as root and launches EPA
     inside every logged-in user's session, and the browser or app starts EPA
     when needed anyway. Also not done: the world-writable (766) desktop file
     Citrix uses; ours is mode 644.
3. **URL and file handlers** that Citrix's own installer registers: `receiver://`,
   `citrixauthwebviewdone://`, `ctxlinuxamloauth://`, `ctxaadsso://`,
   `citrixweb://`, `citrixapp://`, `.cr` store files, plus the `.ica`/`.cr` MIME
   definitions. These make the web portal's "detect Workspace" step work, along
   with the in-app sign-in.
4. **Depends on `webkit2gtk-4.1`** (in Arch's official repos). Version 26.08's app
   window ("selfservice") needs it. The old `webkit2gtk`/`libsoup` optional
   dependencies are gone.
5. **systemd units** (`ctxcwalogd.service`, `ctxusbd.service`) are installed with
   mode 644 instead of 755. Their runtime folders under `/run` are managed with
   `RuntimeDirectory=` instead of `mkdir`/`rm -rf` on `/var/run`.

`citrix/local-changes.patch` holds the same changes as git patches, to re-apply on
top of a newer AUR version.

The usual Citrix telemetry settings come from the AUR package (`Ceip=Disable`,
`DisableHeartBeat=True` in `/opt/Citrix/ICAClient/config/module.ini`).

## Keep AUR helpers from replacing it

`icaclient` also exists in the AUR. An AUR helper such as `paru` or `yay` would see
its version there as an update and replace this build, which would drop EPA and the
handlers. To stop that, add `icaclient` to `IgnorePkg` in `/etc/pacman.conf`.
`IgnorePkg` lines add up, so a new line under `[options]` is fine even if one
already exists:

```sh
sudo sed -i '/^\[options\]/a IgnorePkg = icaclient' /etc/pacman.conf
pacman-conf IgnorePkg    # should list icaclient
```

Installing this build with `sudo pacman -U …` then asks
`icaclient is in IgnorePkg/IgnoreGroup. Install anyway?`. Answer **Y**. Updates
now only happen when you rebuild from this repo.

## After installing Citrix

Each user needs:

```sh
mkdir -p ~/.ICAClient/cache
cp /opt/Citrix/ICAClient/config/{All_Regions,Trusted_Region,Unknown_Region,canonicalization,regions}.ini ~/.ICAClient/
```

pacman prints that reminder on every install **and upgrade**. You only need to do it
once.

The first `.ica` file you open shows Citrix's license agreement. After you accept,
sessions start normally.

### USB redirection (optional)

Passing local USB devices into a Citrix session needs the USB service, which isn't
enabled by default:

```sh
sudo systemctl enable --now ctxusbd
```

It pulls in `ctxcwalogd` (the log writer) automatically. Not tested on this setup
yet.

## License

The package recipe in `citrix/icaclient/` comes from the AUR and is 0BSD (see its
`LICENSE`). Citrix and Omnissa software is downloaded from the vendors at build
time and is under their own licenses. None of it is in this repo.
