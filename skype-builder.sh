#!/bin/sh

APP=skype

# TEMPORARY DIRECTORY
mkdir -p tmp
cd ./tmp || exit 1

# DOWNLOAD APPIMAGETOOL
if ! test -f ./appimagetool; then
	wget -q "$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/"/ /g; s/ /\n/g' | grep -o 'https.*continuous.*tool.*86_64.*mage$')" -O appimagetool
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

ARCH=x86_64 VERSION=$(./appimagetool -v | grep -o '[[:digit:]]*') ./appimagetool -s ./"$APP".AppDir
cd ..
mv ./tmp/*.AppImage ./Skype-"$VERSION"-x86_64.AppImage
