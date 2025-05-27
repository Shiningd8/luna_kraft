#!/bin/bash

# Check if the Pods directory and the target file exist
TARGET_DIR="Pods/PurchasesHybridCommon/ios/PurchasesHybridCommon/PurchasesHybridCommon"
TARGET_FILE="$TARGET_DIR/StoreProduct+HybridAdditions.swift"
SOURCE_FILE="RevenueCatFix/StoreProduct+HybridAdditions.swift"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Target directory does not exist: $TARGET_DIR"
  exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
  echo "Error: Source file does not exist: $SOURCE_FILE"
  exit 1
fi

# Make a backup of the original file
if [ -f "$TARGET_FILE" ]; then
  cp "$TARGET_FILE" "$TARGET_FILE.backup"
  echo "Created backup at $TARGET_FILE.backup"
fi

# Copy the fixed file to the target location
cp "$SOURCE_FILE" "$TARGET_FILE"
echo "Fixed file applied to $TARGET_FILE"

echo "Fix completed successfully!" 