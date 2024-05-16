#!/bin/bash

nc -uzv -w 2 127.0.0.1 9876 > /dev/null 2>&1

# If the command above returns non-zero, the container is unhealthy
health_status=$?
if [ "$health_status" -ne 0 ]; then
    echo "UDP port 9876 is not open"
    exit 1
else
    echo "UDP port 9876 is open"
    exit 0
fi