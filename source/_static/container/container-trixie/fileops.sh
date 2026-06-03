#!/bin/bash

# Create a working directory
mkdir -p /tmp/demo_dir
echo "Created /tmp/demo_dir"

# Create a file
echo "Hello from the container" > /tmp/demo_dir/file.txt
echo "Created file.txt"

# Read the file
echo "Contents of file.txt:"
cat /tmp/demo_dir/file.txt

# Copy the file
cp /tmp/demo_dir/file.txt /tmp/demo_dir/file_copy.txt
echo "Copied file to file_copy.txt"

# Move the file
mv /tmp/demo_dir/file_copy.txt /tmp/demo_dir/file_moved.txt
echo "Moved file_copy.txt to file_moved.txt"

# Append to the file
echo "Appending a line..." >> /tmp/demo_dir/file.txt

# Show updated content
echo "Updated file.txt:"
cat /tmp/demo_dir/file.txt

# Delete the moved file
rm /tmp/demo_dir/file_moved.txt
echo "Deleted file_moved.txt"

echo "=== Done ==="
