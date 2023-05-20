#!/bin/sh

# Get the root TeX Live directory
ROOT=$(kpsewhich --var-value=SELFAUTOPARENT)

if [ $# -ge 2 ]; then
    SOURCE=$1
    TARGET=$2
    echo "Source file: $SOURCE"
    echo "Target file: $TARGET"
else
    echo "Error: Insufficient arguments!"
    exit 1
fi

# Generate lists of package, class, and file names with appropriate suffixes
packages=$(sed -n 's/  \*{package}\s*{\([^}]*\)}.*/\1.sty/p' "$SOURCE")
classes=$(sed -n 's/  \*{class}\s*{\([^}]*\)}.*/\1.cls/p' "$SOURCE")
files=$(sed -n 's/  \*{file}\s*{\([^}]*\)}.*/\1/p' "$SOURCE")

# Concatenate the lists
list="$packages $classes $files"

# Count the total number of items
total=$(echo "$list" | wc -w)

# Initialize the counter
counter=0

# Initialize the package list
package_list=""

# Process each name in the list
for name in $list ; do
    # Increment the counter
    counter=$((counter + 1))

    # Print the progress bar
    # printf "Processing: %s/%s (%.2f%%)\r" "$counter" "$total" "$(echo "$counter / $total * 100" | bc -l)"
    printf "Processing: %s/%s (%.2f%%)\r" "$counter" "$total" "$(echo "scale=4; $counter / $total * 100" | bc)"


    # Run kpsewhich to find the file path
    path=$(kpsewhich "$name")
    # if [[ "$path" == $ROOT* ]]; then
    if [ "${path#$ROOT/}" != "$path" ]; then
        # Remove the root directory from the path
        path="${path#$ROOT/}"
        # Extract the fourth path component (the package name)
        package_name=$(echo "$path" | cut -d'/' -f4)
        # Add the package name to the list
        package_list="$package_list $package_name"
    fi
done

# Sort the list, remove duplicates, and write to the file
# echo "$package_list" | tr ' ' '\n' | sort -u > $TARGET
printf "%s\n" "$package_list" | tr ' ' '\n' | sort -u > "$TARGET"

echo
echo "Processing completed."
