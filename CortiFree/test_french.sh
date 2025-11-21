#!/bin/bash

# Script to test CortiFree app in French
# This script launches the app in the iOS Simulator with French language settings

echo "🇫🇷 Testing CortiFree in French..."

# Kill any existing simulator
echo "Closing existing simulator..."
killall Simulator 2>/dev/null || true

# Set the scheme and configuration
SCHEME="CortiFree"
CONFIGURATION="Debug"
DEVICE="iPhone 16"

# Build the app
echo "Building app..."
xcodebuild -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -configuration "$CONFIGURATION" \
    build

# Get the app bundle path
APP_BUNDLE=$(find ~/Library/Developer/Xcode/DerivedData -name "CortiFree.app" -type d | head -n 1)

if [ -z "$APP_BUNDLE" ]; then
    echo "❌ Error: Could not find CortiFree.app bundle"
    exit 1
fi

echo "Found app bundle at: $APP_BUNDLE"

# Launch the simulator
echo "Launching simulator..."
open -a Simulator

# Wait for simulator to boot
echo "Waiting for simulator to boot..."
sleep 5

# Get the booted device ID
DEVICE_ID=$(xcrun simctl list devices | grep -E "$DEVICE.*Booted" | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}" | head -n 1)

if [ -z "$DEVICE_ID" ]; then
    echo "⚠️  No booted device found, booting $DEVICE..."
    DEVICE_ID=$(xcrun simctl list devices | grep "$DEVICE" | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}" | head -n 1)
    xcrun simctl boot "$DEVICE_ID"
    sleep 5
fi

echo "Using device: $DEVICE_ID"

# Set the device language to French
echo "Setting device language to French..."
xcrun simctl spawn "$DEVICE_ID" defaults write NSGlobalDomain AppleLanguages -array "fr"
xcrun simctl spawn "$DEVICE_ID" defaults write NSGlobalDomain AppleLocale -string "fr_FR"

# Install the app
echo "Installing app..."
xcrun simctl install "$DEVICE_ID" "$APP_BUNDLE"

# Launch the app with French language
echo "Launching CortiFree in French..."
xcrun simctl launch "$DEVICE_ID" Josbiot.App.CortiFree --args -AppleLanguages "(fr)" -AppleLocale "fr_FR"

echo "✅ CortiFree is now running in French!"
echo ""
echo "To switch to English, run:"
echo "  ./test_english.sh"
echo ""
echo "Or manually in the iOS Simulator:"
echo "  Settings > General > Language & Region > iPhone Language > English"