#!/bin/bash

# Script to fix iOS build issues
# Run this from the project root directory

echo "🧹 Starting cleanup process..."

# Step 1: Clean Flutter
echo ""
echo "Step 1: Cleaning Flutter build cache..."
flutter clean

# Step 2: Remove iOS build artifacts
echo ""
echo "Step 2: Removing iOS build artifacts..."
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/Podfile.lock
rm -rf build/

# Step 3: Clean DerivedData (Xcode cache)
echo ""
echo "Step 3: Cleaning Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Step 4: Get Flutter dependencies
echo ""
echo "Step 4: Getting Flutter dependencies..."
flutter pub get

# Step 5: Reinstall Pods
echo ""
echo "Step 5: Reinstalling CocoaPods..."
cd ios
pod deintegrate
pod repo update
pod install --repo-update
cd ..

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Now try building again with:"
echo "  flutter build ios"
echo "or open Xcode and build from there"
