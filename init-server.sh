#!/bin/bash
# Based on server manager from https://github.com/jammsen/docker-palworld-dedicated-server
s=/vrising/server
p=/vrising/data
LOG_COUNT=30


term_handler() {
    echo "Shutting down Server ..."
    PID=$(pgrep -n wine64)
    kill -n 15 $PID && wait $PID
    wineserver -k
    pkill Xvfb
    sleep 1
    echo "Server successfully shut"
    exit
}

cleanup_logs() {
    echo "Keeping only the latest $LOG_COUNT log files"

    # Find all log files and sort them by modification time (newest first)
    log_files=$(find "$p" -name "*.log" -type f -printf "%T@ %p\n" | sort -rn | cut -d' ' -f2-)

    # Keep only the latest $LOGDAYS log files
    latest_logs=$(echo "$log_files" | head -n $LOG_COUNT)

    # Remove the rest of the log files
    for log in $log_files; do
        if ! echo "$latest_logs" | grep -q "$log"; then
            echo "Removing old log: $log"
            rm "$log"
        fi
    done
}

main() {
  trap 'term_handler' SIGTERM

  # Check if we have proper read/write permissions to /palworld
  if [ ! -r "$s" ] || [ ! -w "$s" ]; then
      echo "ERROR: I do not have read/write permissions to $s! Please run "chown -R 1000:1000 $s" on host machine, then try again."
      exit 1
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


  # # Fix for steamclient.so not being found
  # mkdir -p /home/steam/.steam/sdk64
  # cp /home/steam/steamcmd/linux64/steamclient.so ~/.steam/sdk64/steamclient.so

  cleanup_logs

  # Checks if log file exists, if not creates it
  current_date=$(date +"%Y%m%d-%H%M")
  logfile="$current_date-VRisingServer.log"
  if ! [ -f "${p}/$logfile" ]; then
          echo "Creating ${p}/$logfile"
          touch $p/$logfile
  fi

  echo "Launching ARM V Rising"
  echo " "
  # Start server
  v() {
    wine64_cmd="$s/VRisingServer.exe -persistentDataPath $p -logFile $p/$logfile -nographics -batchmode"
    xvfb-run sh -c "env SteamAppId=1604030 wine64 '$wine64_cmd' 2>&1" &
  }
  v
  # Gets the PID of the last command
  ServerPID=$(pgrep -n wine64)

  # Tail log file and waits for Server PID to exit
  tail -n 0 -f $p/$logfile &
  wait $ServerPID
}

main
