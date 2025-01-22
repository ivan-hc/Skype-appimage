#!/bin/sh

APP=skype

# TEMPORARY DIRECTORY
mkdir -p tmp
cd ./tmp || exit 1

# DOWNLOAD APPIMAGETOOL
if ! test -f ./appimagetool; then
	wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
	chmod a+x ./appimagetool
fi

# DOWNLOAD THE SNAP PACKAGE
if ! test -f ./*.snap; then
	wget -q "$(curl -H 'Snap-Device-Series: 16' http://api.snapcraft.io/v2/snaps/info/skype --silent | sed 's/[()",{} ]/\n/g' | grep "^http" | head -1)"
fi

# EXTRACT THE SNAP PACKAGE AND CREATE THE APPIMAGE
unsquashfs -f ./*.snap
mkdir -p "$APP".AppDir
VERSION=$(cat ./squashfs-root/*.yaml | grep "^version" | head -1 | cut -c 10-)
mv ./squashfs-root/usr/share/skypeforlinux/* ./"$APP".AppDir/
mv ./squashfs-root/usr/share/pixmaps/skypeforlinux.png ./"$APP".AppDir/
mv ./squashfs-root/snap/gui/skypeforlinux.desktop ./"$APP".AppDir/
sed -i 's#${SNAP}/meta/gui/skypeforlinux.png#skypeforlinux#g; s#Network;Application;##g' ./"$APP".AppDir/*.desktop

cat >> ./"$APP".AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export UNION_PRELOAD="${HERE}"
exec "${HERE}"/skypeforlinux "$@"
EOF
chmod a+x ./"$APP".AppDir/AppRun

ARCH=x86_64 ./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
	-u "gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|Skype-appimage|continuous|*x86_64.AppImage.zsync" \
	./"$APP".AppDir Skype-"$CHANNEL"-"$VERSION"-x86_64.AppImage || exit 1
