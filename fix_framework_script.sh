#!/bin/bash

# Fix ONNX Runtime frameworks Info.plist files
# This script ensures MinimumOSVersion is set correctly

FRAMEWORKS_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Frameworks"

# Function to fix Info.plist
fix_framework_plist() {
    local framework_path="$1"
    local plist_path="${framework_path}/Info.plist"
    
    if [ -f "$plist_path" ]; then
        echo "Fixing ${framework_path##*/} Info.plist"
        
        # Add MinimumOSVersion if missing
        /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string ${IPHONEOS_DEPLOYMENT_TARGET}" "$plist_path" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion ${IPHONEOS_DEPLOYMENT_TARGET}" "$plist_path"
        
        echo "Set MinimumOSVersion to ${IPHONEOS_DEPLOYMENT_TARGET} for ${framework_path##*/}"
    else
        echo "Warning: Info.plist not found at $plist_path"
    fi
}

# Fix ONNX Runtime frameworks
if [ -d "$FRAMEWORKS_PATH" ]; then
    fix_framework_plist "${FRAMEWORKS_PATH}/onnxruntime.framework"
    fix_framework_plist "${FRAMEWORKS_PATH}/onnxruntime_extensions.framework"
else
    echo "Frameworks directory not found at $FRAMEWORKS_PATH"
fi

echo "Framework Info.plist fix completed"