#!/bin/bash

# Path to the download queue file
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"
DEBUG_LOG="/userdata/system/game-downloader/debug/debug.txt"

# Ensure the debug directory exists
mkdir -p "$(dirname "$DEBUG_LOG")"

# Redirect all stdout and stderr to the debug log file
exec > >(tee -a "$DEBUG_LOG") 2>&1

# Log a script start message
echo "Starting game downloader script at $(date)"

# Function to check for an active internet connection
check_internet() {
    echo "Checking internet connection..."
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        echo "Internet connection is active."
        return 0  # Return 0 if connection is successful
    else
        echo "No internet connection found."
        return 1  # Return 1 if connection fails
    fi
}

# Function to process each download
process_download() {
    local game_name="$1"
    local url="$2"
    local folder="$3"

    game_name=$(echo "$game_name" | sed 's/["]//g')
    local temp_path="/userdata/system/game-downloader/$game_name"

    if [ -f "$temp_path" ]; then
        echo "$game_name is already downloaded. Skipping download."
        return
    fi

    echo "Starting download for $game_name..."
    wget -c "$url" -O "$temp_path" >/dev/null 2>&1 &
    wait $!
    if [ $? -ne 0 ]; then
        echo "Download failed for $game_name"
        return
    fi

    echo "Download succeeded for $game_name"
    process_unzip "$game_name" "$temp_path" "$folder"
}

process_unzip() {
    local game_name="$1"
    local temp_path="$2"
    local folder="$3"

    local game_name_no_ext="${game_name%.zip}"
    local game_folder="/userdata/system/game-downloader/$game_name_no_ext"

    if [ -d "$game_folder" ]; then
        echo "Directory $game_folder exists. Cleaning up."
        rm -rf "$game_folder"
    fi
    mkdir -p "$game_folder"

    echo "Unzipping $game_name..."
    unzip -q "$temp_path" -d "$game_folder"
    if [ $? -ne 0 ]; then
        echo "Unzip failed for $game_name"
        return
    fi

    mv "$game_folder" "$folder"
    echo "Moved unzipped files for $game_name to $folder"
}


# Check for internet connection before proceeding
check_internet
if [ $? -ne 0 ]; then
    echo "No internet connection found. Exiting script."
    exit 1  # Exit the script since there's no internet
fi

# Run the script continuously
while true; do
    echo "Checking for new downloads at $(date)"

    # Process each line in download.txt
    if [[ -f "$DOWNLOAD_QUEUE" ]]; then
        while IFS='|' read -r game_name url folder; do
            echo "Reading download entry: $game_name | $url | $folder"
            
            # Start the download and unzip in parallel (background processes)
            process_download "$game_name" "$url" "$folder" &
        done < "$DOWNLOAD_QUEUE"
    else
        echo "No downloads found in queue."
    fi

    # Wait for a while before checking again for new downloads
    sleep 5
done
