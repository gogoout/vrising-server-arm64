#!/bin/bash

# Path to the Saves directory
SAVES_DIR="/vrising/data/Saves"

# Get the current time
NOW=$(date +%s)

# Check if any files in the Saves directory have been modified within the last 3 minutes
LAST_MODIFIED=$(find "$SAVES_DIR" -type f -printf '%T@\n' | sort -rn | head -n 1)
LAST_MODIFIED_TIME=$(($LAST_MODIFIED + 180))

if [ "$LAST_MODIFIED_TIME" -lt "$NOW" ]; then
    echo "No files updated in the last 3 minutes"
    exit 1
else
    echo "Files updated in the last 3 minutes"
    exit 0
fi