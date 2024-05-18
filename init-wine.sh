  #!/bin/bash
  wine --version
  wine wineboot -i

  wine64 --version
  wine64 wineboot -i
  env WINEPREFIX=~/.wine64 WINE=~/wine/bin/wine64 winetricks -q arch=64 dotnet48

  exit 0