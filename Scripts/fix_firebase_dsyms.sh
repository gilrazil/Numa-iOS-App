#!/bin/bash

# Fix Firebase dSYM Files for App Store Upload
# This script addresses the missing dSYM issue with Firebase frameworks from Swift Package Manager

set -e

echo "🔥 Firebase dSYM Fix Script Started"

# Only run for Release builds and Archive action
if [ "${CONFIGURATION}" != "Release" ] || [ "${ACTION}" != "archive" ]; then
    echo "ℹ️  Skipping dSYM fix - not a Release archive build"
    exit 0
fi

# Define the frameworks that commonly cause dSYM issues
FIREBASE_FRAMEWORKS=(
    "FirebaseFirestoreInternal"
    "absl"
    "grpc"
    "grpcpp"
    "openssl_grpc"
)

# Path to the built products directory
BUILT_PRODUCTS_DIR="${TARGET_BUILD_DIR}"
DSYM_OUTPUT_DIR="${DWARF_DSYM_FOLDER_PATH}"

echo "📁 Built products dir: ${BUILT_PRODUCTS_DIR}"
echo "📁 dSYM output dir: ${DSYM_OUTPUT_DIR}"

# Function to find and copy dSYM files
copy_dsym_if_exists() {
    local framework_name="$1"
    local framework_path="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Frameworks/${framework_name}.framework"
    
    if [ -d "${framework_path}" ]; then
        echo "🔍 Processing ${framework_name}.framework"
        
        # Get the UUID of the framework binary
        local binary_path="${framework_path}/${framework_name}"
        if [ -f "${binary_path}" ]; then
            local uuid=$(dwarfdump --uuid "${binary_path}" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '-')
            
            if [ -n "${uuid}" ]; then
                echo "🆔 Found UUID: ${uuid} for ${framework_name}"
                
                # Try to find the dSYM in various locations
                local dsym_search_paths=(
                    "${BUILD_DIR}/Release-iphoneos"
                    "${BUILD_DIR}/../Release-iphoneos"
                    "${BUILT_PRODUCTS_DIR}"
                    "${CONFIGURATION_BUILD_DIR}"
                    ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release-iphoneos
                )
                
                # Search for the dSYM file
                for search_path in "${dsym_search_paths[@]}"; do
                    local dsym_file="${search_path}/${framework_name}.framework.dSYM"
                    if [ -d "${dsym_file}" ]; then
                        echo "✅ Found dSYM at: ${dsym_file}"
                        
                        # Copy to the archive dSYM directory
                        local dest_dsym="${DSYM_OUTPUT_DIR}/${framework_name}.framework.dSYM"
                        echo "📋 Copying to: ${dest_dsym}"
                        
                        cp -R "${dsym_file}" "${dest_dsym}"
                        
                        # Verify the copy was successful
                        if [ -d "${dest_dsym}" ]; then
                            echo "✅ Successfully copied ${framework_name}.framework.dSYM"
                        else
                            echo "❌ Failed to copy ${framework_name}.framework.dSYM"
                        fi
                        
                        return 0
                    fi
                done
                
                echo "⚠️ No dSYM found for ${framework_name}, this may cause upload issues"
            else
                echo "⚠️ Could not extract UUID from ${framework_name}"
            fi
        else
            echo "⚠️ Binary not found at ${binary_path}"
        fi
    else
        echo "ℹ️ Framework not found: ${framework_name}"
    fi
}

# Process each Firebase framework
for framework in "${FIREBASE_FRAMEWORKS[@]}"; do
    copy_dsym_if_exists "${framework}"
done

# List all dSYM files in the output directory for verification
echo "📋 Final dSYM files in archive:"
if [ -d "${DSYM_OUTPUT_DIR}" ]; then
    find "${DSYM_OUTPUT_DIR}" -name "*.dSYM" -type d | while read dsym_path; do
        dsym_name=$(basename "${dsym_path}")
        echo "  ✓ ${dsym_name}"
    done
else
    echo "  ⚠️ dSYM output directory not found: ${DSYM_OUTPUT_DIR}"
fi

echo "🔥 Firebase dSYM Fix Script Completed" 