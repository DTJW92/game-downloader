#!/bin/bash

# URLs for external scripts
COMBINED_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Main-Menu.sh"
UPDATER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Updater.sh"
DOWNLOAD_MANAGER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Downloadcheck.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/uninstall.sh"

# Initialize global arrays
skipped_games=()
added_games=()

# Function to display the Main Menu
main_menu() {
    local selection
    selection=$(dialog --title "Main Menu" --menu "Select an option:" 15 50 8 \
        1 "Select System Type" \
        2 "Run Updater" \
        3 "Status Checker" \
        4 "Uninstall Game Downloader" \
        5 "Exit" \
        3>&1 1>&2 2>&3)

    case $selection in
        1)
            system_type_menu
            ;;
        2)
            if ! bash <(curl -s "$UPDATER_URL"); then
                dialog --msgbox "Error: Could not run the updater. Check your internet connection or URL." 10 50
            fi
            ;;
        3)
            bash <(curl -s "$DOWNLOAD_MANAGER_URL")
            ;;
        4)
            bash <(curl -s "$UNINSTALL_URL")
            ;;
        5)
            clear
            dialog --infobox "Thank you for using Game Downloader! Any issues, message DTJW92 on Discord!" 10 50
            sleep 3
            exit 0
            ;;
        *)
            main_menu
            ;;
    esac
}

# Function to display the System Type Menu dynamically based on available folders
system_type_menu() {
    local system_type
    local system_types=()
    
    # Dynamically fetch system types from the game-downloader folder
    system_types=($(ls -d /userdata/system/game-downloader/links/*/ | sed 's#.*/##'))

    # Create menu options dynamically based on system types
    menu_options=()
    for system in "${system_types[@]}"; do
        menu_options+=("$system" "$system")
    done

    system_type=$(dialog --title "Select System Type" --menu "Choose a system type" 15 50 4 \
        "${menu_options[@]}" 3>&1 1>&2 2>&3)

    case $system_type in
        *)
            game_system_menu "$system_type"
            ;;
    esac
}

# Function to display the Game System Menu dynamically based on available subdirectories
game_system_menu() {
    local system_type=$1
    local system_dir="/userdata/system/game-downloader/links/$system_type"  # Path to the system's folder
    local game_systems=()

    # List the available game systems for the selected system type
    game_systems=($(ls -d "$system_dir"/*/ | sed 's#.*/##'))

    # Create menu options dynamically
    menu_options=()
    for system in "${game_systems[@]}"; do
        menu_options+=("$system" "$system")
    done

    game_system=$(dialog --title "Select a $system_type Game System" --menu "Choose a system" 15 50 4 \
        "${menu_options[@]}" 3>&1 1>&2 2>&3)

    case $game_system in
        *)
            game_menu "$system_type" "$game_system"
            ;;
    esac
}

# Function to display the Game Menu and select a letter or all games
game_menu() {
    local system_type=$1
    local system=$2
    local DEST_DIR DOWNLOAD_DIR ALLGAMES_FILE

    # Set variables based on the system
    case $system in
        PSX)
            DEST_DIR="/userdata/system/game-downloader/psxlinks"
            DOWNLOAD_DIR="/userdata/roms/psx"
            ALLGAMES_FILE="$DEST_DIR/AllGames.txt"
            ;;
        PS2)
            DEST_DIR="/userdata/system/game-downloader/ps2links"
            DOWNLOAD_DIR="/userdata/roms/ps2"
            ALLGAMES_FILE="$DEST_DIR/AllGames.txt"
            ;;
        GBA)
            DEST_DIR="/userdata/system/game-downloader/gbalinks"
            DOWNLOAD_DIR="/userdata/roms/gba"
            ALLGAMES_FILE="$DEST_DIR/AllGames.txt"
            ;;
        Xbox)
            DEST_DIR="/userdata/system/game-downloader/xboxlinks"
            DOWNLOAD_DIR="/userdata/roms/xbox"
            ALLGAMES_FILE="$DEST_DIR/AllGames.txt"
            ;;
        *)
            dialog --msgbox "Invalid system selected!" 10 50
            return
            ;;
    esac

    select_letter "$system" "$DEST_DIR" "$ALLGAMES_FILE" "$DOWNLOAD_DIR"
}

# Function to select a letter or "All Games" for a system
select_letter() {
    local system=$1
    local DEST_DIR=$2
    local ALLGAMES_FILE=$3
    local DOWNLOAD_DIR=$4

    letter_list=$(ls "$DEST_DIR" | grep -oP '^[a-zA-Z#]' | sort | uniq)

    # Add "All" option to the menu
    menu_options=("All" "All Games")

    if [ -n "$letter_list" ]; then
        while read -r letter; do
            menu_options+=("$letter" "$letter")
        done <<< "$letter_list"
    else
        dialog --msgbox "No letter options available." 10 50
        return
    fi

    selected_letter=$(dialog --title "Select a Letter" --menu "Choose a letter or select 'All Games'" 25 70 10 \
        "${menu_options[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$selected_letter" ]; then
        return 1
    elif [ "$selected_letter" == "All" ]; then
        select_games "AllGames" "$ALLGAMES_FILE" "$DOWNLOAD_DIR"
    else
        select_games "$selected_letter" "$ALLGAMES_FILE" "$DOWNLOAD_DIR"
    fi
}

# Function to display and allow selection of games from the list
select_games() {
    local letter="$1"
    local file="$2"
    local DOWNLOAD_DIR=$3

    if [[ "$letter" == "AllGames" ]]; then
        file="$ALLGAMES_FILE"
    else
        file="$DEST_DIR/${letter}.txt"
    fi

    if [[ ! -f "$file" ]]; then
        dialog --infobox "No games found for selection '$letter'." 5 40
        sleep 2
        return
    fi

    # Read the list of games and prepare the dialog input
    local game_list=()
    while IFS="|" read -r decoded_name game_url; do
        game_list+=("$decoded_name" "" off)
    done < "$file"

    selected_games=$(dialog --title "$system Games" --checklist "Choose games to download" 25 70 10 \
        "${game_list[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$selected_games" ]; then
        return
    fi

    IFS=$'\n'
    for game in $selected_games; do
        game_items=$(echo "$game" | sed 's/\.chd/.chd\n/g')
        while IFS= read -r game_item; do
            if [[ -n "$game_item" ]]; then
                game_item_cleaned=$(echo "$game_item" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')
                if [[ -n "$game_item_cleaned" ]]; then
                    download_game "$game_item_cleaned" "$DOWNLOAD_DIR"
                fi
            fi
        done <<< "$game_items"
    done
}

# Function to download the selected game (add to queue)
download_game() {
    local decoded_name="$1"
    local DOWNLOAD_DIR="$2"

    decoded_name_cleaned=$(echo "$decoded_name" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')

    # Check if the game already exists in the download directory
    if [[ -f "$DOWNLOAD_DIR/$decoded_name_cleaned" ]]; then
        skipped_games+=("$decoded_name_cleaned")
        return
    fi

    # Check if the game is already in the download queue (download.txt)
    if grep -q "$decoded_name_cleaned" "/userdata/system/game-downloader/download.txt"; then
        skipped_games+=("$decoded_name_cleaned")
        return
    fi

    # Add the game to the download queue
    echo "$decoded_name_cleaned" >> "/userdata/system/game-downloader/download.txt"
    added_games+=("$decoded_name_cleaned")
}

# Run the main menu
main_menu