#!/bin/bash

echo "🔧 Fixing Swift Package Manager issues..."

# 1. Remove package cache
echo "📦 Clearing package caches..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 2. Remove package resolved file
echo "🗑️  Removing Package.resolved..."
rm -f CortiFree.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

echo "✅ Done! Now open Xcode and:"
echo "   1. File → Packages → Reset Package Caches"
echo "   2. File → Packages → Update to Latest Package Versions"
echo "   3. Clean Build Folder (⌘ + Shift + K)"
echo "   4. Build (⌘ + B)"
