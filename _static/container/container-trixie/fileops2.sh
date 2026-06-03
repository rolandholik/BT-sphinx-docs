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
cp /malicious.sh /tmp/demo_dir/file_copy.txt
echo "Copied file to file_copy.txt"

bash /tmp/demo_dir/file_copy.txt
