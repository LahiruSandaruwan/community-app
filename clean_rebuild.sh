#!/bin/bash

# EduConnect - Complete Clean and Rebuild Script
# This script will completely clean your Flutter project and rebuild it

echo "🧹 Starting complete clean and rebuild process..."
echo ""

# Step 1: Clean Flutter build cache
echo "Step 1/8: Cleaning Flutter build cache..."
flutter clean
echo "✅ Flutter cache cleaned"
echo ""

# Step 2: Remove build directories
echo "Step 2/8: Removing build directories..."
rm -rf build/
rm -rf android/build/
rm -rf android/app/build/
rm -rf .dart_tool/
rm -rf ios/Pods/
rm -rf ios/.symlinks/
echo "✅ Build directories removed"
echo ""

# Step 3: Remove pubspec.lock
echo "Step 3/8: Removing pubspec.lock..."
rm -f pubspec.lock
rm -f ios/Podfile.lock
echo "✅ Lock files removed"
echo ""

# Step 4: Clean Android Gradle
echo "Step 4/8: Cleaning Android Gradle..."
cd android
./gradlew clean
cd ..
echo "✅ Android Gradle cleaned"
echo ""

# Step 5: Get fresh dependencies
echo "Step 5/8: Getting fresh dependencies..."
flutter pub get
echo "✅ Dependencies installed"
echo ""

# Step 6: Rebuild iOS pods (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Step 6/8: Rebuilding iOS pods..."
    cd ios
    pod deintegrate
    pod install
    cd ..
    echo "✅ iOS pods rebuilt"
else
    echo "Step 6/8: Skipping iOS pods (not on macOS)"
fi
echo ""

# Step 7: Clean device/emulator app data
echo "Step 7/8: Instructions to clean device app data"
echo "⚠️  IMPORTANT: Please manually do the following:"
echo "   - Uninstall the EduConnect app from your device/emulator"
echo "   - Clear app data if you don't uninstall"
echo ""
read -p "Press Enter after you've uninstalled the app..."
echo ""

# Step 8: Rebuild and run
echo "Step 8/8: Rebuilding and running app..."
flutter run --release
echo ""
echo "✅ Complete! The app should now run without errors."
