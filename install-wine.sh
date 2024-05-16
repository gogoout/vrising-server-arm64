#!/bin/bash
set -euxo pipefail
# NOTE: Can only run on aarch64 (since box64 can only run on aarch64)
# box64 runs wine-amd64, box86 runs wine-i386.

### User-defined Wine version variables ################
# - Replace the variables below with your system's info.
# - Note that we need the amd64 version for Box64 even though we're installing it on our ARM processor.
# - Note that we need the i386 version for Box86 even though we're installing it on our ARM processor.
# - Wine download links from WineHQ: https://dl.winehq.org/wine-builds/

branch="$WINE_BRANCH" #example: devel, staging, or stable (wine-staging 4.5+ requires libfaudio0:i386)
version="$WINE_VERSION" #example: "7.1"
id="ubuntu" #example: debian, ubuntu
dist="jammy" #example (for debian): bullseye, buster, jessie, wheezy, ${VERSION_CODENAME}, etc 
tag="-1" #example: -1 (some wine .deb files have -1 tag on the end and some don't)

########################################################

# Wine download links from WineHQ: https://dl.winehq.org/wine-builds/
LNKA="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-amd64/" #amd64-wine links
DEB_A1="wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" #wine64 main bin
DEB_A2="wine-${branch}_${version}~${dist}${tag}_amd64.deb" #wine64 support files (required for wine64 / can work alongside wine_i386 main bin)
DEB_A3="winehq-${branch}_${version}~${dist}${tag}_amd64.deb" #shortcuts & docs
LNKB="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-i386/" #i386-wine links
DEB_B1="wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" #wine_i386 main bin
DEB_B2="wine-${branch}_${version}~${dist}${tag}_i386.deb" #wine_i386 support files (required for wine_i386 if no wine64 / CONFLICTS WITH wine64 support files)
DEB_B3="winehq-${branch}_${version}~${dist}${tag}_i386.deb" #shortcuts & docs

# Install amd64-wine (64-bit) alongside i386-wine (32-bit)
echo -e "Downloading wine . . ."
wget -q ${LNKA}${DEB_A1} 
wget -q ${LNKA}${DEB_A2} 
wget -q ${LNKB}${DEB_B1} 

echo -e "Extracting wine . . ."
dpkg-deb -x ${DEB_A1} wine-installer
dpkg-deb -x ${DEB_A2} wine-installer
dpkg-deb -x ${DEB_B1} wine-installer
echo -e "Installing wine . . ."
mv wine-installer/opt/wine* ~/wine

# Clean up
rm -rf ${DEB_A1} ${DEB_A2} ${DEB_B1}

# Download wine dependencies
# - these packages are needed for running box86/wine-i386 on a 64-bit RPiOS via multiarch
dpkg --add-architecture armhf && apt update -y # enable multi-arch
apt install -y winbind:armhf # to run wine-i386 through box86:armhf on aarch64
apt install -y winbind:arm64


# Install winetricks
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x winetricks
mv winetricks /usr/local/bin/

# Clean up
apt -y autoremove 
apt clean autoclean 
rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists