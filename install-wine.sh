#!/bin/bash
set -euxo pipefail

get_deb_dependencies() {
    local deb_file="$1"
    local suffix="$2"

    # Run dpkg-deb command to get package information
    dependencies=$(dpkg-deb --field "$deb_file" Depends 2>&1)

    # Check for errors
    if [ $? -ne 0 ]; then
        echo "Error parsing .deb file: $dependencies"
        return 1
    fi

  local dependencies_with_suffix=""

  # Remove the "dependencies=" prefix and trim leading/trailing whitespace
  dependencies=$(echo "$dependencies" | sed 's/^dependencies=//' | xargs)

  # Split the string by ',' or '|'
  IFS=',|' read -ra dep_array <<< "$dependencies"

  for dep in "${dep_array[@]}"; do
    # Trim leading and trailing whitespace
    dep=$(echo "$dep" | xargs)

    # Check if the dependency string contains '(>=', and remove it if found
    if [[ "$dep" == *\(* ]]; then
      dep="${dep%% (*}"
    fi

    # Extract the package name
    local package_name="${dep%% *}"

    if [ -n "$dependencies_with_suffix" ]; then
      dependencies_with_suffix+=", "
    fi

    # Append the package name with the suffix
    dependencies_with_suffix+="${package_name}${suffix}"
  done

  echo "$dependencies_with_suffix"
}


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

# Download wine dependencies
# armhf shouldn't be needed for Fex right?
# - these packages are needed for running box86/wine-i386 on a 64-bit RPiOS via multiarch
# dpkg --add-architecture armhf && apt update -y # enable multi-arch
# DEPENDENCIES_A1_HF=$(get_deb_dependencies "$DEB_A1" ":armhf")
# echo "Installing dependencies for $DEB_A1 with armhf suffix..."
# # Install dependencies with apt-get
# # Ignore missing packages with --no-install-recommends
# apt-get install --no-install-recommends --ignore-missing $(echo "$DEPENDENCIES_A1_HF" | tr ', ' ' ') || true

# DEPENDENCIES_A2_HF=$(get_deb_dependencies "$DEB_A2" ":armhf")
# echo "Installing dependencies for $DEB_A2 with armhf suffix..."
# # Install dependencies with apt-get
# # Ignore missing packages with --no-install-recommends
# apt-get install --no-install-recommends --ignore-missing $(echo "$DEPENDENCIES_A2_HF" | tr ', ' ' ') || true

# DEPENDENCIES_B1_HF=$(get_deb_dependencies "$DEB_B1" ":armhf")
# echo "Installing dependencies for $DEB_B1 with armhf suffix..."
# Install dependencies with apt-get
# Ignore missing packages with --no-install-recommends
apt-get install --no-install-recommends --ignore-missing $(echo "$DEPENDENCIES_A3_HF" | tr ', ' ' ') || true

DEPENDENCIES_A1_HF=$(get_deb_dependencies "$DEB_A1" "")
echo "Installing dependencies for $DEB_A1 with suffix..."
# Install dependencies with apt-get
# Ignore missing packages with --no-install-recommends
apt-get install --no-install-recommends --ignore-missing $(echo "$DEPENDENCIES_A1_HF" | tr ', ' ' ') || true

DEPENDENCIES_A2_HF=$(get_deb_dependencies "$DEB_A2" "")
echo "Installing dependencies for $DEB_A2 with suffix..."
# Install dependencies with apt-get
# Ignore missing packages with --no-install-recommends
apt-get install --no-install-recommends --ignore-missing $(echo "$DEPENDENCIES_A2_HF" | tr ', ' ' ') || true

DEPENDENCIES_B1_HF=$(get_deb_dependencies "$DEB_B1" "")
echo "Installing dependencies for $DEB_B1 with suffix..."
# Install dependencies with apt-get
# Ignore missing packages with --no-install-recommends
apt-get install --no-install-recommends --ignore-missing $(echo "$DEPENDENCIES_A3_HF" | tr ', ' ' ') || true

# install some additional stuff
apt install -y winbind # 



# Install winetricks
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x winetricks
mv winetricks /usr/local/bin/

# Clean up
rm -rf ${DEB_A1} ${DEB_A2} ${DEB_B1}
apt -y autoremove 
apt clean autoclean 
rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists