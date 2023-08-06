#!/bin/bash

# Read the source and destination directories from the "directories.txt" file
source=$(head -n 1 "lindirectories.txt")
destination=$(tail -n 1 "lindirectories.txt")

echo "Starting synchronization process..."

# Find the most recently modified file in destination
echo "Looking for the most recently modified file in destination directory..."
recent_file=$(find "$destination" -type f -printf '%T@\t%p\n' | sort -r | head -n1 | cut -f 2-)

# If there are no files in the destination directory, set an old dummy timestamp
if [ -z "$recent_file" ]
then
    echo "No files found in destination directory. Setting default timestamp..."
    recent_file_time="1970-01-01T00:00:00Z"
else
    # Get the timestamp of the most recently modified file
    echo "Getting the timestamp of the most recently modified file in destination directory..."
    recent_file_time_epoch=$(stat -c %Y "$recent_file")
    recent_file_time=$(date -u -d @"$recent_file_time_epoch" +"%Y-%m-%dT%H:%M:%SZ")
fi

# Get the timestamp from the timestamp file in the source directory
echo "Reading timestamp from source directory..."
source_time_file="$source/timestamp"
if [ ! -f "$source_time_file" ]
then
    echo "Timestamp file not found in source directory."
    exit 1
fi

source_timestamp=$(cat "$source_time_file")

# Compare timestamps
echo "Comparing timestamps..."
echo "Source timestamp: $source_timestamp"
echo "Destination timestamp: $recent_file_time"
if [[ "$source_timestamp" > "$recent_file_time" ]]
then
    # Copy differences from source to destination
    echo "Source directory is newer. Updating destination directory..."
    rsync -a --delete --exclude 'timestamp' "$source/" "$destination/"
else
    # Copy differences from destination to source
    echo "Destination directory is newer. Updating source directory..."
    rsync -a --delete "$destination/" "$source/"
    # Update timestamp in the timestamp file
    echo "Updating timestamp in source directory..."
    echo "$recent_file_time" > "$source_time_file"
fi

echo "Synchronization process complete."
