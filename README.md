# zoom.appimage

Repackages the official Zoom Linux tarball (`zoom_x86_64.tar.xz`) as an AppImage.

## Build

```sh
./build.sh                                  # download and package the latest Zoom
ZOOM_VERSION=7.2.1.5760 ./build.sh          # a specific version
./build.sh /path/to/zoom_x86_64.tar.xz      # an already downloaded tarball
```

Downloaded tarballs are cached as `build/zoom_x86_64-<version>.tar.xz`.

The result is `Zoom-<version>-x86_64.AppImage` plus a `.zsync` file for delta updates. `appimagetool` is downloaded
into `build/` on first run.

`resources/` holds the AppRun entry point, desktop file and icon added to the AppDir.

## CI

`.github/workflows/build.yml` checks zoom.us daily and publishes each new Zoom
version as a GitHub Release (tag `v<version>`) with the AppImage attached.
It can also be started manually (Actions → Build AppImage → Run workflow),
optionally for a specific version, and runs on pushes that change the build files.

## Updates (Gear Lever)

The AppImage embeds update information pointing at this repository's latest
GitHub release (`gh-releases-zsync|pick2510|zoom.appimage|latest|Zoom-*x86_64.AppImage.zsync`).
Open it with [Gear Lever](https://github.com/mijorus/gearlever) and it will
detect new releases and update in place; AppImageUpdate works too.
