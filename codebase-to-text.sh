#!/bin/bash

# Script to display filenames and content recursively, saving output to a file.
# Version includes fix to ignore the output file itself.

# --- Configuration ---

# Directory to scan (default: current directory)
# Usage: ./codebase-to-text.sh [directory_path] > codebase_dump.txt
TARGET_DIR="${1:-.}"

# --- !! IMPORTANT !! ---
# Define the output filename - IT MUST MATCH the redirection target
# This name will be ignored during the scan.
OUTPUT_FILENAME="codebase_dump.txt"
# --- !! IMPORTANT !! ---


# Directories/Patterns to ignore (add more as needed)
# Use './' prefix for clarity when TARGET_DIR is '.'
IGNORE_PATHS=(
    "./.git"
    "./.astro"
    "./.env"
    "./public"
    "./.vite"
    "./.idea"
    "./.vscode"
    "./.svn"
    "./.hg"
    "./node_modules"
    "./vendor"
    "./bower_components"
    "./dist"
    "./build"
    "./target"
    "*/__pycache__" # Common python cache
    "./*.pyc"
    "./*.pyo"
    "./*.class"
    "./*.o"
    "./*.so"
    "./*.dll"
    "./*.exe"
    "./*.DS_Store" # macOS specific
    # --- Add the output file to the ignore list ---
    "./${OUTPUT_FILENAME}"
    # Add other binary extensions or build artifact directories
)

# --- Script Logic ---

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' not found." >&2
    exit 1
fi

# Canonicalize TARGET_DIR to handle '.' correctly with relative IGNORE_PATHS
TARGET_DIR_CANONICAL=$(realpath -- "$TARGET_DIR")
# Change to the target directory to simplify relative path matching for find
# Store original CWD to return later if needed
ORIGINAL_CWD=$(pwd)
cd "$TARGET_DIR_CANONICAL" || { echo "Error: Could not change to directory '$TARGET_DIR_CANONICAL'." >&2; exit 1; }

# Print initial status messages to stderr
echo "Scanning codebase in: $TARGET_DIR_CANONICAL" >&2
echo "Output will be redirected (ensure filename matches script: ${OUTPUT_FILENAME})" >&2
echo "Ignoring paths matching patterns (relative to scan dir): ${IGNORE_PATHS[*]}" >&2
echo "==================================================" >&2
echo "" >&2

# Build the find command arguments dynamically in an array
find_args=(find .) # Start with find in the current directory (.)

# Add prune conditions
first_prune=true
for pattern in "${IGNORE_PATHS[@]}"; do
    # Ensure patterns starting without './' still work relative to '.'
    [[ "$pattern" != ./* && "$pattern" != /* ]] && pattern="./$pattern"

    if ! $first_prune; then
        find_args+=(-o) # Add OR before the next path condition
    fi
    find_args+=(-path "$pattern" -prune)
    first_prune=false
done

# Add the final action, OR'd with the last prune condition (if any)
if [ ${#IGNORE_PATHS[@]} -gt 0 ]; then
  find_args+=(-o) # OR after all prunes
fi
# Action: find regular files (-type f) and print them null-delimited (-print0)
find_args+=(-type f -print0)

# Execute the find command using the array and process results with null delimiter via pipe
"${find_args[@]}" | while IFS= read -r -d $'\0' file; do
    # Remove the leading './' for cleaner output if present
    clean_file="${file#./}"

    # Print File Header to stdout (goes to file)
    echo "##################################################"
    echo "### FILE: $clean_file"
    echo "##################################################"
    echo "" # Add a blank line for readability

    # Check if the file is likely binary using 'file' command
    if ! encoding=$(file -b --mime-encoding "$file" 2>/dev/null); then
         # Print Warning to stderr (goes to terminal)
         echo "[WARN] Could not determine encoding for '$clean_file'. Skipping." >&2
         # Print End Marker to stdout (goes to file)
         echo ""
         echo "--- End of $clean_file (skipped due to encoding issue) ---"
         echo "" ; echo ""
         continue
    fi

    if [[ "$encoding" == "binary" ]]; then
        # Print Info to stderr (goes to terminal)
        echo "[INFO] Skipping binary file: $clean_file" >&2
        # Print End Marker to stdout (goes to file)
        echo "[INFO] Skipping binary file." # Also put marker in output file
        echo ""
        echo "--- End of $clean_file (binary) ---"
        echo "" ; echo ""
    elif [ ! -r "$file" ]; then
        # Print Error to stderr (goes to terminal)
        echo "[ERROR] Cannot read file '$clean_file' (check permissions)." >&2
        # Print End Marker to stdout (goes to file)
        echo "[ERROR] Cannot read file (check permissions)." # Also put marker in output file
        echo ""
        echo "--- End of $clean_file (unreadable) ---"
        echo "" ; echo ""
    else
        # Print the content using cat to stdout (goes to file)
        cat "$file"

        # Add a newline to stdout if the file doesn't end with one
        if [ -s "$file" ] && [[ $(tail -c1 "$file" | wc -l) -eq 0 ]]; then
             echo
        fi

        # Print End Marker to stdout (goes to file)
        echo "" # Add a blank line
        echo "--- End of $clean_file ---"
        echo "" # Add more spacing between files
        echo ""
    fi

done # End of while loop connected via pipe

# Return to original directory if needed
# cd "$ORIGINAL_CWD"

# Print final completion messages to stderr
echo "==================================================" >&2
echo "Codebase scan complete. Output should be in ${OUTPUT_FILENAME}" >&2
echo "==================================================" >&2

exit 0
