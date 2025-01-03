#!/usr/bin/env bash

# Get the root TeX Live directory
ROOT=$(kpsewhich --var-value=SELFAUTOPARENT)

# Initialize variables
SOURCE=""
TARGET=""
APPEND=""
REMOVE=""

# Parse command line arguments
while [ $# -gt 0 ]; do
	case "$1" in
	--source)
		SOURCE="$2"
		shift 2
		;;
	--target)
		TARGET="$2"
		shift 2
		;;
	--append)
		APPEND="$2"
		shift 2
		;;
	--remove)
		REMOVE="$2"
		shift 2
		;;
	*)
		echo "Error: Unknown parameter $1"
		exit 1
		;;
	esac
done

# Check mandatory arguments
if [ -z "$SOURCE" ] || [ -z "$TARGET" ]; then
	echo "Error: --source and --target are mandatory!"
	echo "Usage: $0 --source <source_file> --target <target_file> [--append <append_list>] [--remove <remove_list>]"
	exit 1
fi

# Print arguments for debugging
echo "Source file: $SOURCE"
echo "Target file: $TARGET"
if [ -n "$APPEND" ]; then
	echo "Packages to append: $APPEND"
fi
if [ -n "$REMOVE" ]; then
	echo "Packages to remove: $REMOVE"
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
package_list=$APPEND

# Process each name in the list
for name in $list; do
	# Increment the counter
	counter=$((counter + 1))

	# Print the progress bar
	LC_NUMERIC="en_US.UTF-8" printf "[%3.f%%] %3s/%3s %s -> " "$(bc -l <<<"$counter / $total * 100")" "$counter" "$total" "$name"

	# Run kpsewhich to find the file path
	path=$(kpsewhich "$name")

	if [ "${path#"$ROOT"/}" != "$path" ]; then
		# Remove the root directory from the path
		path="${path#"$ROOT"/}"
		# Extract the fourth path component (the package name)
		package_name=$(echo "$path" | cut -d'/' -f4)
		# Add the package name to the list
		package_list="$package_list $package_name"
		printf "%s\n" "$package_name"
	else
		printf "SKIP\n"
	fi
done

# Sort the list, remove duplicates, remove filtered, and write to the file
printf "%s " "$package_list" | sed 's/^ *//' | tr ' ' '\n' | sort -u | grep -v -x -f <(echo "$REMOVE" | tr ' ' '\n') | cat >"$TARGET"
