#!/bin/bash

# IMPORTANT: This script is designed exclusively for use within the Makefile target 'db-setup'.
# It depends on specific environment variables and assumes it's executed from the project root.
# Direct execution of this script outside the 'make db-setup' command is not supported.

# Validate environment variables
echo "Validating environment variables..."
[ -z "$POSTGRES_USER" ] && echo "POSTGRES_USER is not set" && exit 1
[ -z "$POSTGRES_DB" ] && echo "POSTGRES_DB is not set" && exit 1
[ -z "$POSTGRES_CONTAINER" ] && echo "POSTGRES_CONTAINER is not set" && exit 1
[ -z "$BACKUP_DIR" ] && echo "BACKUP_DIR is not set" && exit 1
echo "Environment variables validated."

# Set file permissions
echo "Setting up file permissions..."
chmod -R 755 ./init
chmod -R 755 ./config
chmod -R 755 ./scripts
echo "File permissions have been set."
