#!/bin/bash

# Display animated title for installer
animate_title() {
    local text="GAME DOWNLOADER INSTALLER"
    local delay=0.03
    local length=${#text}
    for (( i=0; i<length; i++ )); do
        echo -n "${text:i:1}"
        sleep $delay
    done
    echo
}

# Function to display controls
display_controls() {
    echo
    echo "  This will install the Game Downloader app in Ports."
    echo
    sleep 3  # Delay for 3 seconds
}

# Function to download files and handle errors
download_file() {
    local url=$1
    local dest=$2
    if ! curl -L "$url" -o "$dest"; then
        dialog --msgbox "Error downloading $url. Please check your network connection or the URL." 7 50
        exit 1
    fi
}

# Create debug directory at the start
mkdir -p /userdata/system/game-downloader/debug
mkdir -p /userdata/system/game-downloader/Images  # Create the Images folder
mkdir -p /userdata/roms/ports/videos  # Create the videos folder

# Main execution
clear
animate_title
display_controls

# Download the four files and save them in the Images folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/Game%20Downloader%20Wheel.png" "/userdata/roms/ports/images/Game_Downloader_Wheel.png"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/Game%20Downloader%20Video.mp4" "/userdata/roms/ports/videos/GameDownloader-video.mp4"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/Game%20Downloader%20Icon.png" "/userdata/roms/ports/images/Game_Downloader_Icon.png"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/Game%20Download%20Box%20Art.png" "/userdata/roms/ports/images/Game_Downloader_Box_Art.png"

# Download and save download.sh locally (always replace)
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/download.sh" "/userdata/system/services/download.sh"

# Convert download.sh to Unix format and set proper permissions
dos2unix /userdata/system/services/download.sh
chmod +x /userdata/system/services/download.sh  # Ensure it's executable
chmod 777 /userdata/system/services/download.sh  # Set read/write/execute permissions

# Rename the file to remove the .sh extension (optional, since you want to avoid .sh)
mv /userdata/system/services/download.sh /userdata/system/services/Background_Game_Downloader

# Ensure the script is executable
chmod +x /userdata/system/services/Background_Game_Downloader  # Make sure the service script is executable

# Enable and start the service in the background
batocera-services enable Background_Game_Downloader
batocera-services start Background_Game_Downloader &

# Download GMD.sh and save it as GameDownloader.sh in Ports folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/GMD.sh" "/userdata/roms/ports/GameDownloader.sh"

# Make the downloaded GameDownloader.sh executable
chmod +x /userdata/roms/ports/GameDownloader.sh

# Define URLs for the scraper scripts
PSX_SCRAPER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-scraper.sh"
DC_SCRAPER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-scraper.sh"
PS2_SCRAPER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/ps2-scraper.sh"

# Run scraper scripts directly from GitHub
echo "Running PSX scraper..."
if ! bash <(curl -s "$PSX_SCRAPER") >/dev/null 2>&1; then
    dialog --msgbox "Error running PSX scraper." 7 50
    exit 1
fi

echo "Running Dreamcast scraper..."
if ! bash <(curl -s "$DC_SCRAPER") >/dev/null 2>&1; then
    dialog --msgbox "Error running Dreamcast scraper." 7 50
    exit 1
fi

echo "Running PS2 scraper..."
if ! bash <(curl -s "$PS2_SCRAPER") >/dev/null 2>&1; then
    dialog --msgbox "Error running PS2 scraper." 7 50
    exit 1
fi

# Download bkeys.txt and save it as GameDownloader.sh.keys in the Ports folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/bkeys.txt" "/userdata/roms/ports/GameDownloader.sh.keys"

# Define the path to the gamelist.xml
GAMELIST="/userdata/roms/ports/gamelist.xml"

# Create a new XML entry to add with additional fields
NEW_ENTRY="<game>
    <path>./GameDownloader.sh</path>
    <name>Game Downloader</name>
    <image>./images/Game_Downloader_Icon.png</image>
    <video>./videos/GameDownloader-video.mp4</video>
    <marquee>./images/Game_Downloader_Wheel.png</marquee>
    <thumbnail>./images/Game_Downloader_Box_Art.png</thumbnail>
    <lang>en</lang>
</game>"

# Append the new entry to the gamelist.xml
echo "$NEW_ENTRY" >> "$GAMELIST"

echo "Gamelist.xml has been updated."

echo "Installation complete. 'Game Downloader' should now be available in Ports."
echo "Batocera will initiate the background downloader automatically, you should find a toggle switch for it within Main Menu -> System Settings -> Services."
echo "Rebooting the system for the changes to take effect."
sleep 5
reboot
