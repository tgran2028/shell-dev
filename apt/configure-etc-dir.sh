#!/usr/bin/env bash

# Configures hidden folder on /etc that enables a group of users to (1) mirror contents as needed for confguring changes,
# and (2) to push changes to the main configuration files.
#

# Create a hidden folder on /etc
DIR="/etc/.config-change-mgmt"/
