#!/bin/bash

# Base URL and destination directory
BASE_URL="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Game%20Boy%20Advance/"
DEST_DIR="/userdata/system/game-downloader/links/Game Boy Advance"
ROM_DIR="/userdata/roms/gba"  # Fixed missing closing quote
EXT=".zip"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Function to decode URL (ASCII decode)
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Clear all the text files before writing new data
clear_all_files() {
    rm -f "$DEST_DIR"/*.txt
    echo "All game list files have been cleared."
}

# Clear all text files before starting
clear_all_files

# Fetch the page content
page_content=$(curl -s "$BASE_URL")

# Get total number of URLs (total steps) to process
total_steps=$(echo "$page_content" | grep -oP "(?<=href=\")[^\"]*${EXT}" | wc -l)

# If there are no links, exit early
if [ "$total_steps" -eq 0 ]; then
    echo "No matching files found for scraping."
    exit 1
fi

# Initialize the current step
current_step=0

# Parse .zip links, decode them, and check for Europe
echo "$page_content" | grep -oP "(?<=href=\")[^\"]*${EXT}" | while read -r game_url; do
    # Decode the URL and check for the region tags and (En) in the decoded text
    decoded_name=$(decode_url "$game_url")

    if [[ "$decoded_name" =~ Europe ]]; then
        # Process games matching the "Europe" criteria

        # Format the entry with backticks around the decoded name
        quoted_name="\`$decoded_name\`"

        # Get the first character of the decoded file name
        first_char="${decoded_name:0:1}"
        
        # Append to AllGames.txt with both quoted decoded name and original URL
        echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/AllGames.txt"
        
        # Save to the appropriate letter-based file
        if [[ "$first_char" =~ [a-zA-Z] ]]; then
            first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')
            echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/${first_char}.txt"
        elif [[ "$first_char" =~ [0-9] ]]; then
            echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/#.txt"
        else
            echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/other.txt"
        fi
    fi

    # Update progress
    current_step=$((current_step + 1))
    progress=$((current_step * 100 / total_steps))
    
    # Emit progress to the parent script
    echo $progress
done

echo "Scraping complete!"
