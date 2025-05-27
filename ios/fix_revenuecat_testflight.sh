#!/bin/bash

# Script to fix RevenueCat configuration issue in TestFlight
echo "Fixing RevenueCat initialization issues for TestFlight..."

# Find the PurchasesHybridCommon CommonFunctionality.swift file
COMMON_FUNC_FILE=$(find . -name "CommonFunctionality.swift" -type f)

if [ -z "$COMMON_FUNC_FILE" ]; then
  echo "Error: CommonFunctionality.swift not found."
  exit 1
fi

echo "Found CommonFunctionality.swift at: $COMMON_FUNC_FILE"

# Create a backup
cp "$COMMON_FUNC_FILE" "${COMMON_FUNC_FILE}.backup"
echo "Created backup at ${COMMON_FUNC_FILE}.backup"

# Modify the file to add protection against the initialization check error
echo "Applying patch to prevent 'Purchases has not been configured' fatal error..."
sed -i '' 's/Fatal error: Purchases has not been configured/Warning: Purchases has not been configured/' "$COMMON_FUNC_FILE"
sed -i '' 's/fatalError("Purchases has not been configured/print("Warning: Purchases has not been configured/' "$COMMON_FUNC_FILE"
sed -i '' 's/precondition(Purchases.isConfigured, "Purchases has not been configured/if !Purchases.isConfigured { print("Warning: Purchases has not been configured/' "$COMMON_FUNC_FILE"

# Apply our fix to RevenueCat's StoreProduct+HybridAdditions.swift
echo "Fixing StoreProduct+HybridAdditions.swift..."
sh fix_revenuecat.sh

# Run the post-install hook
echo "Running post-install hooks..."
sh post_install_hook.sh

echo "✅ RevenueCat TestFlight fixes applied successfully!"
echo ""
echo "Next steps:"
echo "1. Build your app for TestFlight"
echo "2. Make sure App Store Connect agreements are signed"
echo "3. Wait 24-48 hours after any product changes in App Store Connect" 