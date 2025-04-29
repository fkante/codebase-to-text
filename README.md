# Codebase Content Aggregator Script (`codebase-to-text.sh`)

This Bash script recursively scans a specified directory (or the current directory by default) and aggregates the content of all non-ignored text files into a single output file.
It's useful for creating a snapshot of a codebase to feed to any AI for review or analysis.

## Features

- **Recursive Scan:** Traverses subdirectories.
- **Configurable Ignore List:** Easily exclude specific directories (like `.git`, `node_modules`, `dist`), file patterns, or individual files.
- **Output File Exclusion:** Automatically ignores the specified output file to prevent it from including itself in the scan.
- **Binary File Detection:** Attempts to identify and skip binary files, printing only a marker message.
- **Clear Output Formatting:** Each file's content is preceded by a header (`### FILE: path/to/file`) and followed by an end marker (`--- End of path/to/file ---`).
- **Status Messages:** Prints progress, warnings, and errors to standard error (stderr), keeping the standard output (stdout) clean for file content.
- **Permission Handling:** Checks for read permissions and reports errors for unreadable files.

## Prerequisites

- A Unix-like environment with Bash shell.
- Standard Unix utilities like `find`, `cat`, `realpath`, `file`, `tail`, `wc`.

## Usage

1.  **Navigate** to the directory containing the script or provide the path to it.
2.  **Execute** the script, redirecting its standard output to your desired filename.
3.  **IMPORTANT:** Ensure the filename you redirect to (`your_output_file.txt` in the example) **exactly matches** the `OUTPUT_FILENAME` variable defined _inside_ the script.

```bash
# Example: Scan the current directory and save to codebase_dump.txt
./codebase-to-text.sh > codebase_dump.txt

# Example: Scan a specific directory (../my_project) and save to my_project_code.txt
# (Make sure to change OUTPUT_FILENAME inside the script to "my_project_code.txt" first!)
./codebase-to-text.sh ../my_project > my_project_code.txt
```

## Configuration (Inside the Script)

You can modify the script's behavior by editing these variables near the top:

- `TARGET_DIR`: The default directory to scan if none is provided as a command-line argument. Set using `TARGET_DIR="${1:-.}"`.
- `OUTPUT_FILENAME`: **Crucial!** This **must** match the filename used for output redirection (`> filename.txt`). The script uses this name to exclude the output file itself from the scan. Default is `"codebase_dump.txt"`.
- `IGNORE_PATHS`: An array of paths and patterns to exclude from the scan. Paths are treated relative to the `TARGET_DIR`. Add or remove patterns as needed.

## Output

The script sends:

- **File content and headers/footers:** To standard output (stdout), which should be redirected to a file.
- **Status messages, warnings, and errors:** To standard error (stderr), which will appear on your terminal during execution.

The output file will contain the concatenated content of all scanned files, formatted like this:

```
##################################################
### FILE: path/to/some/file.txt
##################################################

Content of file.txt...

--- End of path/to/some/file.txt ---


##################################################
### FILE: another/directory/script.js
##################################################

Content of script.js...

--- End of another/directory/script.js ---


```

If a file is skipped (e.g., binary, unreadable), a corresponding message will be included in the output file.

## Notes

- Always double-check that the `OUTPUT_FILENAME` variable in the script matches the filename you use for redirection (`>`). Mismatches will cause the script to either fail to ignore the output file (potentially including it in itself) or ignore the wrong file.
- The script changes the current directory to the target directory during execution using `cd`. It attempts to return to the original directory upon completion, but be mindful of this if incorporating it into larger workflows.
