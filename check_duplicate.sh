#!/bin/bash

# check_duplicate.sh - Check if a file has duplicates in a directory
# Usage: check_duplicate.sh <source_file> <target_directory>
# Returns: 0 if duplicate found (prints duplicate filename), 1 if no duplicate found

source_file="$1"
target_dir="$2"

# Validate inputs
if [[ -z "$source_file" || -z "$target_dir" ]]; then
    echo "Usage: $0 <source_file> <target_directory>" >&2
    exit 2
fi

if [[ ! -f "$source_file" ]]; then
    echo "Error: Source file does not exist: $source_file" >&2
    exit 2
fi

if [[ ! -d "$target_dir" ]]; then
    echo "Error: Target directory does not exist: $target_dir" >&2
    exit 2
fi

# Compare with all existing files in target directory
for existing_file in "$target_dir"/*; do
    # Skip if no files match the glob or if it's the same file
    if [[ ! -e "$existing_file" ]] || [[ "$existing_file" -ef "$source_file" ]]; then
        continue
    fi
    
    # Skip directories
    if [[ -d "$existing_file" ]]; then
        continue
    fi
    
    # Compare file contents
    if cmp -s "$source_file" "$existing_file" 2>/dev/null; then
        # Found duplicate - return the name of the existing file
        basename "$existing_file"
        exit 0
    fi
done

# No duplicate found
exit 1 