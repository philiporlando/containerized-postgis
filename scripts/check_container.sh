#!/bin/bash
# check_container.sh

# Check if any containers for the 'database' profile are running
if docker compose --profile database ps -q | grep -q .; then
    exit 0  # Exit with 0 if containers are running
else
    echo "Containers are already stopped or do not exist."
    exit 1  # Exit with 1 if no containers are running
fi
