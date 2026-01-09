#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "🔧 Applying CocoaPods 1.16.2 macOS Sequoia workaround..."

# Fix permissions aggressively
echo "📝 Fixing permissions..."
chmod -R 777 . 2>/dev/null || true
chmod -R 777 ~/Library/Developer/Xcode/DerivedData 2>/dev/null || true

# Remove temp files that cause issues
echo "🗑️ Removing temp files..."
rm -rf /var/folders/*/T/.atomos* 2>/dev/null || true
rm -rf Pods/Pods.xcodeproj/xcuserdata 2>/dev/null || true

# Try pod install with special handling
echo "📦 Running pod install..."
/opt/homebrew/bin/pod install --repo-update 2>&1 || {
    echo "⚠️ Pod install failed, applying aggressive fix..."
    
    # Kill any Xcode processes that might have file locks
    killall Xcode 2>/dev/null || true
    sleep 1
    
    # Try again with different approach
    rm -rf Pods
    /opt/homebrew/bin/pod install --repo-update 2>&1 || true
}

echo "✅ Done!"
