#!/bin/sh

APP=skype
mkdir tmp
cd ./tmp
wget -q "$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/"/ /g; s/ /\n/g' | grep -o 'https.*continuous.*tool.*86_64.*mage$')" -O appimagetool
chmod a+x ./appimagetool

VERSION=$(curl -v --silent https://repo.skype.com/deb/dists/stable/main/binary-amd64/Packages 2>&1 | grep -m 1 -Eo "Version: [+-]?[0-9]+([.][0-9]+)?+[+-]?[0-9]+([.][0-9]+)?" | cut -c 10-)
wget https://go.skype.com/skypeforlinux-64.deb
ar x skypeforlinux-64.deb
tar fx data.tar.gz
mkdir $APP.AppDir
mv ./usr/share/skypeforlinux/* ./$APP.AppDir/
mv ./usr/share/pixmaps/skypeforlinux.png ./$APP.AppDir/
mv ./usr/share/applications/skypeforlinux.desktop ./$APP.AppDir/

cat >> ./$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export UNION_PRELOAD="${HERE}"
exec "${HERE}"/skypeforlinux "$@"
EOF
chmod a+x ./$APP.AppDir/AppRun
ARCH=x86_64 VERSION=$(./appimagetool -v | grep -o '[[:digit:]]*') ./appimagetool -s ./$APP.AppDir
cd ..
mv ./tmp/*.AppImage ./Skype-$VERSION-x86_64.AppImage
