#!/bin/bash

# This script fixes issues with RevenueCat's purchase library on iOS
# It modifies specific files to avoid naming conflicts with StoreKit

echo "Running post-install hook for RevenueCat compatibility..."

# Path to the specific file that needs to be fixed
TARGET_FILE="Pods/PurchasesHybridCommon/ios/PurchasesHybridCommon/PurchasesHybridCommon/StoreProduct+HybridAdditions.swift"

if [ -f "$TARGET_FILE" ]; then
  echo "Found RevenueCat file, applying fix..."
  
  # Create a backup
  cp "$TARGET_FILE" "${TARGET_FILE}.backup"
  
  # Replace ambiguous SubscriptionPeriod references with RevenueCat.SubscriptionPeriod
  sed -i '' 's/subscriptionPeriod: SubscriptionPeriod/subscriptionPeriod: RevenueCat.SubscriptionPeriod/g' "$TARGET_FILE"
  sed -i '' 's/subscriptionPeriodUnit: SubscriptionPeriod.Unit/subscriptionPeriodUnit: RevenueCat.SubscriptionPeriod.Unit/g' "$TARGET_FILE"
  
  echo "RevenueCat fix applied successfully!"
else
  echo "RevenueCat file not found, skipping fix."
fi

echo "Post-install hook completed." 