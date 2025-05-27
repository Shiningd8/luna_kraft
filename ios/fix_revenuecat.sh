#!/bin/bash

# Script to fix RevenueCat SubscriptionPeriod ambiguity
echo "Fixing RevenueCat SubscriptionPeriod ambiguity..."

# Target file path
TARGET_FILE="Pods/PurchasesHybridCommon/ios/PurchasesHybridCommon/PurchasesHybridCommon/StoreProduct+HybridAdditions.swift"

# Check if the file exists
if [ ! -f "$TARGET_FILE" ]; then
    echo "Error: Target file not found at $TARGET_FILE"
    exit 1
fi

# Create a backup
cp "$TARGET_FILE" "${TARGET_FILE}.backup"

# Use sed to directly modify the file
# Replace the ambiguous SubscriptionPeriod with fully qualified RevenueCat.SubscriptionPeriod
sed -i '' 's/static func rc_normalized(subscriptionPeriod: SubscriptionPeriod)/static func rc_normalized(subscriptionPeriod: RevenueCat.SubscriptionPeriod)/g' "$TARGET_FILE"
sed -i '' 's/static func rc_normalized(subscriptionPeriodUnit: SubscriptionPeriod.Unit)/static func rc_normalized(subscriptionPeriodUnit: RevenueCat.SubscriptionPeriod.Unit)/g' "$TARGET_FILE"

echo "Fix applied to $TARGET_FILE"
echo "Done!" 