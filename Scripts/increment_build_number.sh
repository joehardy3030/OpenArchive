#!/bin/sh
# Set CFBundleVersion in the built app's Info.plist to the number of git commits.
# When run from Xcode, uses BUILT_PRODUCTS_DIR and WRAPPER_NAME.
# Can also be run manually: increment_build_number.sh [path to Info.plist]

set -e

if [ -n "$1" ]; then
    PLIST="$1"
else
    PLIST="${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Info.plist"
fi

if [ ! -f "$PLIST" ]; then
    echo "warning: Info.plist not found at $PLIST"
    exit 0
fi

BUILD_NUMBER=$(git -C "${SRCROOT}" rev-list --count HEAD 2>/dev/null || echo "1")
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$PLIST"
echo "Set CFBundleVersion to $BUILD_NUMBER"
