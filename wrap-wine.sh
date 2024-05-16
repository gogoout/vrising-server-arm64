#!/bin/sh
set -euxo pipefail

# Install wrapper script for box86 & box64
cat << EOF > /usr/local/bin/wine
#!/bin/sh
WINEPREFIX=~/.wine WINEARCH=win32 FEXBash "~/wine/bin/wine \$@"
EOF
cat << EOF > /usr/local/bin/wine64
#!/bin/sh
WINEPREFIX=~/.wine64 WINEARCH=win64 FEXBash "~/wine/bin/wine64 \$@"
EOF
cat << EOF > /usr/local/bin/wineserver
#!/bin/sh
WINEPREFIX=~/.wine64 WINEARCH=win64 FEXBash "~/wine/bin/wineserver \$@"
EOF
ln -s ~/wine/bin/wineboot /usr/local/bin/wineboot
ln -s ~/wine/bin/winecfg /usr/local/bin/winecfg
chmod +x /usr/local/bin/wine /usr/local/bin/wine64 /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver
