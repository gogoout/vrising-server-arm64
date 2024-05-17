#!/bin/bash

# Path to the Saves directory
SAVES_DIR="/vrising/data/Saves"

# Get the current time in seconds since the epoch
NOW=$(date +%s)

# Find the last modified time of files in the Saves directory (in seconds since the epoch)
LAST_MODIFIED=$(find "$SAVES_DIR" -type f -printf '%T@\n' | sort -rn | head -n 1)

# Convert the LAST_MODIFIED to an integer (strip off the fractional part)
LAST_MODIFIED_INT=$(printf "%.0f" "$LAST_MODIFIED")

# Calculate the threshold time (last modified time + 180 seconds)
LAST_MODIFIED_TIME=$(($LAST_MODIFIED_INT + 180))

# Check if the threshold time is less than the current time
if [ "$LAST_MODIFIED_TIME" -lt "$NOW" ]; then
    echo "No files updated in the last 3 minutes"
    exit 1
else
    echo "Files updated in the last 3 minutes"
    exit 0
fi
