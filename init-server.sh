#!/bin/bash
# Based on server manager from https://github.com/jammsen/docker-palworld-dedicated-server
s=/vrising/server
p=/vrising/data

wine wineboot -i && wine64 wineboot -i

function main() {

  # Check if we have proper read/write permissions to /palworld
  if [ ! -r "$s" ] || [ ! -w "$s" ]; then
      echo "ERROR: I do not have read/write permissions to $s! Please run "chown -R 1000:1000 $s" on host machine, then try again."
      exit 1
  fi

  if [ -z "$SERVERNAME" ]; then
    SERVERNAME="arm vrising"
  fi
  if [ -z "$WORLDNAME" ]; then
    WORLDNAME="world1"
  fi
  game_port=""
  if [ ! -z $GAMEPORT ]; then
    game_port=" -gamePort $GAMEPORT"
  fi
  query_port=""
  if [ ! -z $QUERYPORT ]; then
    query_port=" -queryPort $QUERYPORT"
  fi

  # Check for SteamCMD and server updates
  echo " "
  echo "Updating V-Rising Dedicated Server files..."
  echo " "
  FEXBash "./steamcmd/steamcmd.sh +@sSteamCmdForcePlatformType windows +force_install_dir $s +login anonymous +app_update 1829350 validate +quit"
  echo "steam_appid: "`cat $s/steam_appid.txt`

  mkdir "$p/Settings" 2>/dev/null
  if [ ! -f "$p/Settings/ServerGameSettings.json" ]; then
          echo "$p/Settings/ServerGameSettings.json not found. Copying default file."
          cp "$s/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json" "$p/Settings/"
  fi
  if [ ! -f "$p/Settings/ServerHostSettings.json" ]; then
          echo "$p/Settings/ServerHostSettings.json not found. Copying default file."
          cp "$s/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json" "$p/Settings/"
  fi


  # Fix for steamclient.so not being found
  mkdir -p /home/steam/.steam/sdk64
  cp /home/steam/steamcmd/linux64/steamclient.so ~/.steam/sdk64/steamclient.so


  # Checks if log file exists, if not creates it
  current_date=$(date +"%Y%m%d-%H%M")
  logfile="$current_date-VRisingServer.log"
  if ! [ -f "${p}/$logfile" ]; then
          echo "Creating ${p}/$logfile"
          touch $p/$logfile
  fi

  echo "Starting Xvfb"
  Xvfb :0 -screen 0 1024x768x16 &

  echo "Launching wine64 V Rising using $SERVERNAME"
  echo " "
  # Start server
  set SteamAppId=1604030
  DISPLAY=:0.0 wine64 "$s/VRisingServer.exe -persistentDataPath $p -logFile $p/$logfile"
}

main