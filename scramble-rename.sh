#!/bin/bash

# Usage: scramble-rename.sh [-y|--yes] <directory>
# Scrambles all filenames in a directory for testing purposes

set -e

# Parse arguments
AUTO_CONFIRM=false
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -y|--yes)
      AUTO_CONFIRM=true
      shift
      ;;
    -*|--*)
      echo "Unknown option $1"
      echo "Usage: $0 [-y|--yes] <directory>"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# Restore positional parameters
set -- "${POSITIONAL_ARGS[@]}"

DIR="$1"

if [[ -z "$DIR" ]]; then
  echo "Usage: $0 [-y|--yes] <directory>"
  echo ""
  echo "Options:"
  echo "  -y, --yes    Non-interactive mode, automatically confirm all prompts"
  echo ""
  echo "Description:"
  echo "  Scrambles all filenames in the specified directory with random names."
  echo "  Useful for testing the smart-rename tool. File extensions are preserved."
  echo ""
  echo "Examples:"
  echo "  $0 ~/test_files/"
  echo "  $0 -y ./documents/"
  exit 1
fi

# Check if directory exists
if [[ ! -d "$DIR" ]]; then
  echo "❌ Directory not found: $DIR"
  exit 1
fi

# Function to generate random filename
generate_random_name() {
  local length=${1:-8}
  local chars="abcdefghijklmnopqrstuvwxyz0123456789"
  local result=""
  
  for ((i=0; i<length; i++)); do
    result+="${chars:RANDOM%${#chars}:1}"
  done
  
  echo "$result"
}

echo "🎲 File Scrambler"
echo "=================="
echo "Directory: $DIR"
echo ""

# Scan files and build list
files_to_process=()
total_files=0

echo "🔍 Scanning files..."

for FILE in "$DIR"/*; do
  BASENAME="$(basename "$FILE")"
  
  # Skip if the glob didn't match anything (empty directory)
  if [[ ! -e "$FILE" ]]; then
    continue
  fi
  
  # Only process files (not directories) and skip hidden files
  if [[ -f "$FILE" && ! "$BASENAME" =~ ^\. ]]; then
    files_to_process+=("$FILE")
    echo "  ✓ $BASENAME"
    total_files=$((total_files + 1))
  else
    # Show what we're skipping and why
    if [[ -d "$FILE" ]]; then
      echo "  ⏭ $BASENAME (directory - skipped)"
    elif [[ -L "$FILE" ]]; then
      echo "  ⏭ $BASENAME (symlink - skipped)"
    elif [[ "$BASENAME" =~ ^\. ]]; then
      echo "  ⏭ $BASENAME (hidden file - skipped)"
    elif [[ ! -f "$FILE" ]]; then
      echo "  ⏭ $BASENAME (not a regular file - skipped)"
    else
      echo "  ⏭ $BASENAME (unknown reason - skipped)"
    fi
  fi
done

if [[ $total_files -eq 0 ]]; then
  echo "❌ No files found in $DIR"
  echo "Note: Hidden files (starting with .) are skipped"
  exit 1
fi

echo ""
echo "📊 Summary"
echo "=========="
echo "Files to scramble: $total_files"
echo ""

# Ask for user confirmation
if [[ "$AUTO_CONFIRM" == "false" ]]; then
    echo "⚠️  This will rename all files with random names!"
    read -p "Do you want to proceed with scrambling? (y/n): " confirm
    echo ""
else
    confirm="y"
    echo "⚠️  Auto-confirm mode: proceeding with scrambling..."
    echo ""
fi

if [[ ! $confirm =~ ^[Yy]$ ]]; then
  echo "❌ Operation cancelled by user."
  exit 0
fi

echo "🎲 Scrambling filenames..."
echo ""

# Create a backup log of original names
BACKUP_LOG="$DIR/.scramble_backup_$(date +%Y%m%d_%H%M%S).txt"
echo "📝 Creating backup log: $BACKUP_LOG"
echo "# Scramble backup created: $(date)" > "$BACKUP_LOG"
echo "# Original -> Scrambled" >> "$BACKUP_LOG"
echo "" >> "$BACKUP_LOG"

# Keep track of used names to avoid collisions
files_processed=0

# Main processing
for FILE in "${files_to_process[@]}"; do
  BASENAME="$(basename "$FILE")"
  EXT=""
  
  # Extract extension if present
  if [[ "$BASENAME" == *.* ]]; then
    EXT=".${BASENAME##*.}"
  fi
  
  # Generate unique random name
  attempts=0
  max_attempts=100
  
  while [[ $attempts -lt $max_attempts ]]; do
    # Generate random name (8-15 characters for better uniqueness)
    name_length=$((8 + RANDOM % 8))
    RANDOM_NAME=$(generate_random_name $name_length)
    NEW_BASENAME="${RANDOM_NAME}${EXT}"
    NEW_PATH="$DIR/$NEW_BASENAME"
    
    # Check if file already exists (simpler than tracking used names)
    if [[ ! -e "$NEW_PATH" ]]; then
      break
    fi
    
    attempts=$((attempts + 1))
  done
  
  if [[ $attempts -eq $max_attempts ]]; then
    echo "  ⚠️  Could not generate unique name for $BASENAME (too many files?)"
    continue
  fi
  
  # Rename the file
  mv "$FILE" "$NEW_PATH"
  echo "  $BASENAME -> $NEW_BASENAME"
  echo "$BASENAME -> $NEW_BASENAME" >> "$BACKUP_LOG"
  files_processed=$((files_processed + 1))
done

echo ""
echo "✅ Scrambling complete!"
echo ""
echo "📊 Final Summary"
echo "==============="
echo "Files found: $total_files"
echo "Files scrambled: $files_processed"

if [[ $files_processed -lt $total_files ]]; then
  skipped=$((total_files - files_processed))
  echo "Files skipped: $skipped"
fi

echo ""
echo "💡 Tips:"
echo "   • Use your smart-rename.sh to restore meaningful names"
echo "   • Original filenames are lost - this is for testing only"
echo "   • File extensions are preserved for compatibility" 