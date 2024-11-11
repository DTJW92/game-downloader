#!/bin/bash

# Ensure clear display
clear

# Welcome message
echo "Welcome to the Game Downloader. This test is updated."
sleep 2

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
    echo "Error: dialog is not installed. Please install it and try again."
    exit 1
fi

# Define the URLs to fetch the menu scripts from GitHub
PSX_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-downloader-menu.sh"
DC_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-downloader-menu.sh"

# Download the PSX and Dreamcast downloader scripts from GitHub
echo "Downloading PSX and Dreamcast downloader menus from GitHub..."
curl -L "$PSX_MENU_URL" -o /userdata/system/game-downloader/psx-downloader-menu.sh
curl -L "$DC_MENU_URL" -o /userdata/system/game-downloader/dc-downloader-menu.sh

# Ensure the scripts have the correct permissions
chmod +x /userdata/system/game-downloader/psx-downloader-menu.sh
chmod +x /userdata/system/game-downloader/dc-downloader-menu.sh

# Main dialog menu
dialog --clear --backtitle "Game Downloader" \
       --title "Select a System" \
       --menu "Choose an option:" 15 50 4 \
       1 "PSX Downloader" \
       2 "Dreamcast Downloader" 2>/tmp/game-downloader-choice

# Read user choice
choice=$(< /tmp/game-downloader-choice)
rm /tmp/game-downloader-choice

# Act based on choice
case $choice in
    1)
        /userdata/system/game-downloader/psx-downloader-menu.sh
        ;;
    2)
        /userdata/system/game-downloader/dc-downloader-menu.sh
        ;;
    *)
        echo "No valid option selected."
        ;;
esac

# Clear screen on exit
clear
