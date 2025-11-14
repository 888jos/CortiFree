#!/bin/bash

# Firebase Setup Checker for CortiFree

echo "🔥 Firebase Setup Checker"
echo "========================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check GoogleService-Info.plist
echo "📋 Checking Firebase Configuration Files..."
if [ -f "GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅${NC} GoogleService-Info.plist found"
else
    echo -e "${RED}❌${NC} GoogleService-Info.plist NOT found"
    echo "   → Download it from Firebase Console"
fi
echo ""

# Check if firebase-ios-sdk is in Package.resolved
echo "📦 Checking Package Dependencies..."
if [ -f "../CortiFree.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    if grep -q "firebase-ios-sdk" "../CortiFree.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"; then
        echo -e "${GREEN}✅${NC} Firebase iOS SDK installed"
    else
        echo -e "${RED}❌${NC} Firebase iOS SDK NOT installed"
        echo "   → Add via Xcode Package Dependencies"
    fi
else
    echo -e "${YELLOW}⚠️${NC}  No Package.resolved found (packages not yet resolved)"
    echo "   → Add Firebase via Xcode: File > Add Packages..."
fi
echo ""

# Check Firebase imports in source files
echo "🔍 Checking Firebase Imports in Code..."
firebase_files=$(grep -l "import Firebase" **/*.swift 2>/dev/null | wc -l)
echo "   Found $firebase_files files using Firebase"
echo ""

# Instructions
echo "================================"
echo "📖 Next Steps"
echo "================================"
echo ""
echo "If Firebase is NOT installed:"
echo "1. Open Xcode"
echo "2. Project > Package Dependencies > +"
echo "3. Add: https://github.com/firebase/firebase-ios-sdk"
echo "4. Select: FirebaseAuth, FirebaseFirestore"
echo "5. Build (Cmd+B)"
echo ""
echo "For detailed instructions, see:"
echo "→ FIX_BUILD_ERROR.md (quick fix)"
echo "→ FIREBASE_SETUP.md (detailed guide)"
echo ""
