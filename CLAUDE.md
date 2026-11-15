# Notes for Claude Code

The owner uses this repo to reinstall two VDI clients on a fresh Arch-based system
(CachyOS). Read README.md, horizon/README.md and this file first.

## Ground rules

- **Keep the home folder tidy.** Clone and build in a fresh directory under `/tmp`,
  and delete it after installing. Leave no `~/aur` or build files in `~`.
  (`~/.ICAClient` and `~/.omnissa` are expected; the clients create those.)
- **Root:** for anything that needs root, give the user short one-line `sudo`
  commands to run themselves. Long commands get wrapped and break when pasted.
  `makepkg` itself never needs root.
- **Review before building.** Read every PKGBUILD and install script before
  building, including this repo's Citrix recipe, and especially after changing it.
- **Don't `ldd` vendor binaries.** It can run them. Use
  `/usr/lib/ld-linux-x86-64.so.2 --list` or `readelf -d`.
- Things may have changed since Nov 2026. Check the current AUR and vendor state;
  don't assume these notes are still current.

## Omnissa Horizon

1. Clone `https://aur.archlinux.org/omnissa-horizon-client.git` into /tmp, review
   it, and check whether it's flagged out of date.
2. Have the user install missing dependencies with `sudo pacman -S --needed …`,
   run `makepkg`, then have them install **only** the main
   `omnissa-horizon-client-*.pkg.tar.zst` with `sudo pacman -U …`.
3. Before the first launch, have them create
   `/etc/omnissa/horizon-mandatory-config` containing
   `view.enableDataSharing = "FALSE"`. After the first launch, verify the setting
   took effect, and update horizon/README.md with the result. It wasn't verified
   when this was written.

## Citrix Workspace (icaclient)

The customised recipe is in `citrix/icaclient/`. Its local changes are summarised
in README.md and are also in `citrix/local-changes.patch` (against AUR commit
`77eafb5`).

1. **Check versions.** Compare `pkgver` in `citrix/icaclient/PKGBUILD` with:
   - the version on Citrix's download page, which is
     `url` in the PKGBUILD; look for `linuxx64-<version>.tar.gz`
   - the current AUR `icaclient`
2. **If Citrix is still on our version:** copy `citrix/icaclient/` to /tmp and
   build it there.
3. **If Citrix has a newer version:**
   - Bump `pkgver`, reset `pkgrel=1`, and set `sha256sums_x86_64` (and
     `_aarch64`) to the SHA-256 **published on Citrix's download page** for the
     tarball. Never use a checksum computed from the download.
   - If the AUR package has caught up, consider re-basing instead: clone the AUR,
     apply `citrix/local-changes.patch` (`git am -3`), and drop whatever upstream
     already does.
   - Run `makepkg -o --nodeps` to download, verify and extract. Then check that
     every file and directory `package()` references still exists in
     `src/linuxx64/linuxx64.cor`, and that the EPA tar
     (`EPA/linuxvpn-*.tar`) is still laid out the same way.
   - Re-check the EPA gpgme symbols. Extract the binary to /tmp, then compare
     `readelf --dyn-syms` undefined gpgme symbols against the defined symbols of
     `/usr/lib/libgpgme.so`. Treat `@` and `@@` as equivalent.
   - Re-check every Citrix binary's libraries with `readelf -d` NEEDED against
     `ldconfig -p`. A library change is how the webkit2gtk 4.0 → 4.1 switch
     showed up.
   - Commit and push the updated recipe to this repo, regenerating `.SRCINFO`
     with `makepkg --printsrcinfo` and `local-changes.patch`.
4. **Protect it from AUR helpers.** Run `pacman-conf IgnorePkg`. If `icaclient`
   isn't listed, have the user run:
   `sudo sed -i '/^\[options\]/a IgnorePkg = icaclient' /etc/pacman.conf`
   Otherwise `paru`/`yay` would replace this build with the plain AUR one (no EPA,
   no handlers). Repeated `IgnorePkg` lines add up, so this is safe even if one
   already exists. Run `pacman-conf IgnorePkg` again to confirm.
5. **Install:** have the user run `sudo pacman -S --needed` for missing
   dependencies, build with `makepkg`, then `sudo pacman -U` the package. Because
   of `IgnorePkg`, pacman asks "icaclient is in IgnorePkg/IgnoreGroup. Install
   anyway?"; tell the user to answer Y.
6. **Per-user setup:** create `~/.ICAClient/cache` and copy in the region .ini
   files (see README.md). Don't overwrite existing files.
7. **USB redirection** is optional. Only if the user wants it, have them run
   `sudo systemctl enable --now ctxusbd`. That also starts `ctxcwalogd`.
8. **Verify:**
   - `ld.so --list` on `wfica`, `selfservice` and `/opt/Citrix/Browser-EPA/nsgcepa`
     with `LD_LIBRARY_PATH=/opt/Citrix/Browser-EPA/compat`. Nothing should show
     "not found".
   - Check the handlers with `xdg-mime query default` for:
     `x-scheme-handler/{receiver,citrixauthwebviewdone,ctxaadsso,citrixapp,nsgcepa}`,
     `application/x-ica` and `application/vnd.citrix.receiver.configure`.
   - Check the EPA binaries' SHA-256 against `epaHash` and `epalibHash` in
     `/opt/Citrix/Browser-EPA/version.json`.
   - Telemetry is off:
     `grep -E '^(EnableCeip|DisableHeartBeat)=' /opt/Citrix/ICAClient/config/module.ini`
     must show `EnableCeip=Disable` and `DisableHeartBeat=True`. `module.ini` is a pacman
     `backup` file, so if it was edited, an upgrade leaves a `module.ini.pacnew`
     instead of replacing it. Check the live file.
   - `pacman-conf IgnorePkg` lists `icaclient`.
9. Tell the user that the first `.ica` file shows the license agreement, and that
   the reminder about `~/.ICAClient` reappears on every upgrade and can be ignored.

## After a gpgme update: re-test EPA

EPA reaches Arch's gpgme 2.x through the `compat/libgpgme.so.11` link, which points
at `/usr/lib/libgpgme.so`. A gpgme update can rename the library or drop symbols, and
EPA would then fail silently during a gateway sign-in. Whenever `gpgme` has been
upgraded (check `grep -E 'upgraded gpgme ' /var/log/pacman.log`), re-test:

- `LD_LIBRARY_PATH=/opt/Citrix/Browser-EPA/compat /usr/lib/ld-linux-x86-64.so.2 --list /opt/Citrix/Browser-EPA/nsgcepa`
  shows no "not found", and `libgpgme.so.11` resolves through `compat/`.
- Every undefined gpgme symbol of `nsgcepa` (`readelf --dyn-syms -W`, `UND`,
  currently `GPGME_1.0`/`GPGME_1.1`) is defined in `/usr/lib/libgpgme.so`. Normalise
  `@@` to `@` before comparing.
- `/opt/Citrix/Browser-EPA/compat/libgpgme.so.11` isn't a dangling link.

If a symbol is missing, tell the user that EPA will break on this gpgme. Don't patch
the EPA binary (its hash is checked); look for a Citrix EPA update instead.

## Known behaviour

- EPA (the device check) opens in its own window. It works from the browser
  sign-in, and the user reported it also works during the app's own sign-in.
- Harmless log noise: `lldpcli: command not found` from wfica, and OpenH264
  frame-skip warnings.
