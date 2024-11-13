#!/bin/bash

# Directory for the status files
STATUS_DIR="/userdata/system/game-downloader/status"
mkdir -p "$STATUS_DIR"

# Path to the download queue file
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"

# Run the script continuously
while true; do
    # Check if download.txt exists and has content
    if [[ -f "$DOWNLOAD_QUEUE" ]]; then
        # Process each line in download.txt
        while IFS='|' read -r game_name url folder; do
            # Set the status file path (using game_name as the file name)
            status_file="$STATUS_DIR/$game_name.status"

            # Log initial status
            echo "Starting download for $game_name from $url" > "$status_file"

            # Download the file
            file_name="$(basename "$url")"
            output_path="$folder/$file_name"
            
            # Download with progress and update the status file with percentage
            wget -c "$url" -O "$output_path" --progress=dot 2>&1 | \
            awk '/[0-9]%/ {gsub(/[\.\%]/,""); print $1}' | while read -r progress; do
                echo "$progress" > "$status_file"
            done

            # Check if download was successful
            if [ $? -ne 0 ]; then
                echo "Error: Failed to download $url" >> "$status_file"
            else
                # Mark download as complete
                echo "100" > "$status_file"

                # Move the downloaded file to the target folder
                mv "$output_path" "$folder"

                # Delete the status file once download is complete
                rm -f "$status_file"

                # Remove the processed line from download.txt
                sed -i "/$game_name|/d" "$DOWNLOAD_QUEUE"
            fi
        done < "$DOWNLOAD_QUEUE"
    fi

    # Wait for a while before checking again for new downloads
    sleep 5
done
