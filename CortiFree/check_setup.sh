#!/bin/bash

# CortiFree Setup Checker
# This script verifies that all necessary files are in place

echo "🔍 CortiFree Setup Checker"
echo "=========================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
total=0
passed=0
failed=0

# Function to check file
check_file() {
    ((total++))
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅${NC} $2"
        ((passed++))
    else
        echo -e "${RED}❌${NC} $2"
        ((failed++))
    fi
}

# Function to check directory
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✅${NC} $2"
    else
        echo -e "${RED}❌${NC} $2"
    fi
}

echo "📁 Checking Project Structure..."
echo "--------------------------------"
check_dir "Models" "Models directory"
check_dir "Services" "Services directory"
check_dir "ViewModels" "ViewModels directory"
check_dir "Views" "Views directory"
check_dir "Components" "Components directory"
check_dir "Utilities" "Utilities directory"
echo ""

echo "📦 Checking Models..."
echo "-------------------"
check_file "Models/User.swift" "User.swift"
check_file "Models/Task.swift" "Task.swift"
check_file "Models/UserStats.swift" "UserStats.swift"
check_file "Models/Exercise.swift" "Exercise.swift"
check_file "Models/DefaultTasks.swift" "DefaultTasks.swift"
echo ""

echo "⚙️  Checking Services..."
echo "----------------------"
check_file "Services/FirebaseService.swift" "FirebaseService.swift"
check_file "Services/SoundPlayer.swift" "SoundPlayer.swift"
echo ""

echo "🧠 Checking ViewModels..."
echo "------------------------"
check_file "ViewModels/HomeViewModel.swift" "HomeViewModel.swift"
check_file "ViewModels/TasksViewModel.swift" "TasksViewModel.swift"
check_file "ViewModels/LibraryViewModel.swift" "LibraryViewModel.swift"
check_file "ViewModels/ProfileViewModel.swift" "ProfileViewModel.swift"
echo ""

echo "📱 Checking Views..."
echo "------------------"
check_file "Views/HomeView.swift" "HomeView.swift"
check_file "Views/TasksView.swift" "TasksView.swift"
check_file "Views/LibraryView.swift" "LibraryView.swift"
check_file "Views/ProfileView.swift" "ProfileView.swift"
echo ""

echo "🧩 Checking Components..."
echo "------------------------"
check_file "Components/GradientOrb.swift" "GradientOrb.swift"
check_file "Components/ProgressCircle.swift" "ProgressCircle.swift"
check_file "Components/TaskRow.swift" "TaskRow.swift"
check_file "Components/StatsChart.swift" "StatsChart.swift"
check_file "Components/MiniPlayer.swift" "MiniPlayer.swift"
echo ""

echo "🛠  Checking Utilities..."
echo "-----------------------"
check_file "Utilities/ColorExtension.swift" "ColorExtension.swift"
check_file "Utilities/HapticManager.swift" "HapticManager.swift"
check_file "Utilities/ConfettiModifier.swift" "ConfettiModifier.swift"
check_file "Utilities/AppConstants.swift" "AppConstants.swift"
echo ""

echo "📄 Checking App Files..."
echo "-----------------------"
check_file "CortiFreeApp.swift" "CortiFreeApp.swift"
check_file "ContentView.swift" "ContentView.swift"
echo ""

echo "📚 Checking Documentation..."
echo "---------------------------"
check_file "README.md" "README.md"
check_file "IMPLEMENTATION_NOTES.md" "IMPLEMENTATION_NOTES.md"
check_file "NEXT_STEPS.md" "NEXT_STEPS.md"
check_file "PROJECT_SUMMARY.md" "PROJECT_SUMMARY.md"
echo ""

echo "⚠️  Checking Optional Files..."
echo "-----------------------------"
echo -e "${YELLOW}ℹ️${NC}  Poppins fonts (to be added manually)"
echo -e "${YELLOW}ℹ️${NC}  Audio files: rain.mp3, ocean.mp3, fire.mp3, whitenoise.mp3"
echo -e "${YELLOW}ℹ️${NC}  GoogleService-Info.plist (Firebase config)"
echo ""

echo "================================"
echo "📊 Summary"
echo "================================"
echo "Total checks: $total"
echo -e "${GREEN}Passed: $passed${NC}"
if [ $failed -gt 0 ]; then
    echo -e "${RED}Failed: $failed${NC}"
else
    echo -e "${GREEN}Failed: 0${NC}"
fi
echo ""

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}✅ All core files are in place!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Add Poppins fonts to the project"
    echo "2. Add audio files (rain.mp3, ocean.mp3, fire.mp3, whitenoise.mp3)"
    echo "3. Update Info.plist with font names"
    echo "4. Build and run the project"
    echo ""
    echo -e "${GREEN}🚀 Ready to continue development!${NC}"
else
    echo -e "${RED}❌ Some files are missing!${NC}"
    echo "Please check the output above for missing files."
fi
