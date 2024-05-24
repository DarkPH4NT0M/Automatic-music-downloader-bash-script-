#!/bin/bash

# Script: music_downloader.sh
# Description: Downloads music from a YouTube playlist, renames files, and moves them to a specified folder.
# Author: Your Name
# Date: Insert Date

# Turn on Wi-Fi
su -c svc wifi enable

# Maximum time to wait for Wi-Fi connection (in seconds)
max_wait_time=60
current_wait_time=0

# Function to check internet connectivity
check_internet_connection() {
    ping -c 1 google.com > /dev/null 2>&1
}

# Check if device is connected to the internet with a maximum wait time
while [ $current_wait_time -lt $max_wait_time ]; do
    if check_internet_connection; then
        echo "Connected to the internet"
        break
    else
        echo "Not connected to the internet. Waiting..."
        sleep 5  # Adjust the sleep time based on your network conditions
        current_wait_time=$((current_wait_time + 5))
    fi
done

# If the maximum wait time is reached and still not connected, exit the script
if [ $current_wait_time -ge $max_wait_time ]; then
    echo "Timed out waiting for internet connection. Exiting."
    su -c svc wifi disable
    pkill -f "com.termux"
fi

# Create Mymusics folder if it doesn't exist
mymusics_directory="/storage/emulated/0/Mymusics"
if [ ! -d "$mymusics_directory" ]; then
    mkdir -p "$mymusics_directory"
fi

# Create download_temp folder if it doesn't exist
download_temp="$mymusics_directory/download_temp"
if [ ! -d "$download_temp" ]; then
    mkdir -p "$download_temp"
fi

# Create temporary folders
download_temp="/storage/emulated/0/Mymusics/download_temp"
rename_directory="$download_temp/rename"

mkdir -p "$rename_directory"

# Step 1: Download music from YouTube playlist
yt-dlp -i -f ba -x --geo-bypass --download-archive "$download_temp/music_download.archive" --embed-thumbnail -o "$download_temp/%(playlist_index)s. %(title)s [%(id)s].%(ext)s" "https://youtube.com/playlist?list=PLXFzz_xH35n39TzOIWmJqDVbQJmPLttEZ"

# Move downloaded opus files to rename folder
find "$download_temp" -type f -name "*.opus" -exec mv {} "$rename_directory" \;

# Step 3: Rename files in rename folder using the provided script with inverse logic
# Set the directory path
directory="$rename_directory"

# Calculate the starting number as 1 more than the highest number in /storage/emulated/0/Mymusics
start=$(($(ls /storage/emulated/0/Mymusics | grep -oP '^\d+' | sort -nr | head -n 1) + 1))

# Find all files in the directory that match the pattern 'XXXX.*'
files=("$directory"/*.*)

# Reverse the order to start with the highest number
for ((i = ${#files[@]} - 1; i >= 0; i--)); do
  old_file="${files[i]}"
  # Exclude rename.sh from renaming
  if [[ "$old_file" != *"rename.sh"* ]]; then
    old_num=$(echo "$old_file" | grep -oP '(\d+)(?=\.)')
    new_num=$((start + ${#files[@]} - 1 - i))
    new_file="${old_file/$old_num/$new_num}"
    mv "$old_file" "$new_file"
    echo "Renamed: $old_file to $new_file"
  fi
done

# Move opus files from rename folder to Mymusics folder
mymusics_directory="/storage/emulated/0/Mymusics"
mv "$rename_directory"/*.opus "$mymusics_directory"

# Turn off Wi-Fi
su -c svc wifi disable

# End of script
pkill -f "com.termux"
