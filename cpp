#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: cpp filename.cpp"
  exit 1
fi

filename="$1"
basename=$(basename "$filename" .cpp)
binary="/tmp/$basename-$$.out"  # Use a temporary binary with unique name

g++ "$filename" -o "$binary" -std=c++20 -Wall

if [ $? -eq 0 ]; then
  echo "Running..."
  "$binary"
  rm "$binary"
else
  echo "Compilation failed."
fi
