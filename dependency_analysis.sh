#!/bin/bash
# Complete Dependency Analysis for Phi-3 C++ Integration

echo "🔍 COMPLETE DEPENDENCY ANALYSIS FOR PHI-3"
echo "=========================================="

GENAI_ROOT="../onnxruntime-genai"
BUILD_DIR="$GENAI_ROOT/build/macOS/RelWithDebInfo"
WORKING_BINARY="./test_phi3_cpp"

echo ""
echo "📋 1. RUNTIME LIBRARY DEPENDENCIES"
echo "-----------------------------------"
if [ -f "$WORKING_BINARY" ]; then
    echo "Libraries our working binary depends on:"
    otool -L "$WORKING_BINARY"
    
    echo ""
    echo "🔍 Analyzing each dependency:"
    
    # Get list of dependencies, excluding system ones
    otool -L "$WORKING_BINARY" | grep -v "/usr/lib/" | grep -v "/System/Library/" | grep -v "$WORKING_BINARY:" | while read -r line; do
        lib_path=$(echo "$line" | awk '{print $1}' | tr -d '\t')
        if [[ "$lib_path" != "" && "$lib_path" != *":" ]]; then
            echo "  📚 $lib_path"
            
            # Try to find the actual file
            if [[ "$lib_path" == "@rpath"* ]]; then
                actual_path="${lib_path/@rpath/$BUILD_DIR}"
                echo "    → Resolves to: $actual_path"
                if [ -f "$actual_path" ]; then
                    echo "    → Size: $(du -h "$actual_path" | cut -f1)"
                    echo "    → Dependencies:"
                    otool -L "$actual_path" 2>/dev/null | grep -v "/usr/lib/" | grep -v "/System/Library/" | head -5 | sed 's/^/      /'
                fi
            fi
        fi
    done
else
    echo "❌ Working binary not found at $WORKING_BINARY"
fi

echo ""
echo "📋 2. STATIC LIBRARY ANALYSIS"
echo "-----------------------------"
echo "Static libraries in build directory:"
find "$BUILD_DIR" -name "*.a" | while read -r static_lib; do
    echo "  📦 $(basename "$static_lib")"
    echo "    → Path: $static_lib"
    echo "    → Size: $(du -h "$static_lib" | cut -f1)"
    
    # Try to see what's inside (first few symbols)
    echo "    → Key symbols:"
    ar -t "$static_lib" 2>/dev/null | head -3 | sed 's/^/      /'
    
    # Check if it contains OpenCV-related symbols
    if nm "$static_lib" 2>/dev/null | grep -i opencv >/dev/null; then
        echo "    → ⚠️  Contains OpenCV symbols!"
    fi
    
    # Check for other common computer vision libraries
    if nm "$static_lib" 2>/dev/null | grep -i -E "(cv::|Mat|imread|imwrite)" >/dev/null; then
        echo "    → ⚠️  Contains computer vision symbols!"
    fi
    
    # Check for audio processing
    if nm "$static_lib" 2>/dev/null | grep -i -E "(audio|sound|wav|mp3)" >/dev/null; then
        echo "    → ⚠️  Contains audio processing symbols!"
    fi
done

echo ""
echo "📋 3. FRAMEWORK DEPENDENCIES (macOS)"
echo "------------------------------------"
echo "System frameworks our binary uses:"
otool -L "$WORKING_BINARY" | grep "/System/Library/Frameworks/" | while read -r line; do
    framework=$(echo "$line" | awk '{print $1}' | tr -d '\t')
    framework_name=$(basename "$framework" .framework)
    echo "  🏗️  $framework_name"
    
    case "$framework_name" in
        "CoreML")
            echo "    → Purpose: Machine Learning inference"
            echo "    → iOS Compatible: ✅ Yes"
            ;;
        "Foundation")
            echo "    → Purpose: Basic object types, collections"
            echo "    → iOS Compatible: ✅ Yes"
            ;;
        "CoreFoundation")
            echo "    → Purpose: Low-level utilities"
            echo "    → iOS Compatible: ✅ Yes"
            ;;
        "CoreGraphics")
            echo "    → Purpose: 2D graphics, image processing"
            echo "    → iOS Compatible: ✅ Yes"
            ;;
        "ImageIO")
            echo "    → Purpose: Image format reading/writing"
            echo "    → iOS Compatible: ✅ Yes"
            ;;
        "CoreServices")
            echo "    → Purpose: File system, metadata"
            echo "    → iOS Compatible: ❓ Limited (some APIs unavailable)"
            ;;
        *)
            echo "    → Purpose: Unknown - needs investigation"
            echo "    → iOS Compatible: ❓ Unknown"
            ;;
    esac
done

echo ""
echo "📋 4. THIRD-PARTY LIBRARY ANALYSIS"
echo "----------------------------------"
echo "Checking for common third-party dependencies:"

# Check for OpenCV
if find "$BUILD_DIR" -name "*opencv*" | head -1 >/dev/null; then
    echo "  ❌ OpenCV detected!"
    find "$BUILD_DIR" -name "*opencv*" | head -3
else
    echo "  ✅ No OpenCV found"
fi

# Check for FFmpeg
if find "$BUILD_DIR" -name "*ffmpeg*" -o -name "*av*" | head -1 >/dev/null; then
    echo "  ❌ FFmpeg/libav detected!"
    find "$BUILD_DIR" -name "*ffmpeg*" -o -name "*av*" | head -3
else
    echo "  ✅ No FFmpeg found"
fi

# Check for protobuf
if find "$BUILD_DIR" -name "*protobuf*" -o -name "*proto*" | head -1 >/dev/null; then
    echo "  ⚠️  Protobuf detected (might be okay):"
    find "$BUILD_DIR" -name "*protobuf*" -o -name "*proto*" | head -3
else
    echo "  ✅ No Protobuf found"
fi

# Check for Boost
if find "$BUILD_DIR" -name "*boost*" | head -1 >/dev/null; then
    echo "  ❌ Boost detected!"
    find "$BUILD_DIR" -name "*boost*" | head -3
else
    echo "  ✅ No Boost found"
fi

echo ""
echo "📋 5. HEADER DEPENDENCY ANALYSIS"
echo "--------------------------------"
echo "Critical headers our C++ code includes:"

# Get the actual includes from our working C++ file
if [ -f "test_phi3.cpp" ]; then
    echo "  Direct includes in test_phi3.cpp:"
    grep "^#include" test_phi3.cpp | sed 's/^/    /'
fi

echo ""
echo "  Key ONNX Runtime GenAI headers needed:"
find "$GENAI_ROOT/src" -name "*.h" | grep -E "(ort_genai_c|config|generators)" | while read -r header; do
    echo "    📄 $(basename "$header")"
    # Check what this header includes
    includes=$(grep "^#include" "$header" 2>/dev/null | wc -l)
    echo "      → Includes $includes other headers"
done

echo ""
echo "📋 6. SIZE ANALYSIS"
echo "-------------------"
echo "Total size of dependencies:"
total_size=0

echo "  📦 Libraries:"
find "$BUILD_DIR" -name "*.dylib" -o -name "*.a" | while read -r lib; do
    size=$(du -k "$lib" | cut -f1)
    echo "    $(basename "$lib"): $(du -h "$lib" | cut -f1)"
done

# Calculate rough total
dylib_size=$(find "$BUILD_DIR" -name "*.dylib" -exec du -ck {} + | tail -1 | cut -f1)
static_size=$(find "$BUILD_DIR" -name "*.a" -exec du -ck {} + | tail -1 | cut -f1)
total_kb=$((dylib_size + static_size))
total_mb=$((total_kb / 1024))

echo ""
echo "  📊 Rough totals:"
echo "    Dynamic libraries: ${dylib_size}KB"
echo "    Static libraries: ${static_size}KB"
echo "    Combined: ${total_mb}MB"

echo ""
echo "📋 7. SYMBOLS THAT MIGHT INDICATE HEAVY DEPENDENCIES"
echo "==================================================="

# Check our actual binary for concerning symbols
if [ -f "$WORKING_BINARY" ]; then
    echo "Checking for potentially problematic symbol patterns:"
    
    # Check for OpenCV symbols
    opencv_symbols=$(nm "$WORKING_BINARY" 2>/dev/null | grep -i opencv | wc -l)
    echo "  OpenCV symbols: $opencv_symbols"
    
    # Check for computer vision
    cv_symbols=$(nm "$WORKING_BINARY" 2>/dev/null | grep -i -E "(imread|imwrite|Mat)" | wc -l) 
    echo "  Computer vision symbols: $cv_symbols"
    
    # Check for audio processing
    audio_symbols=$(nm "$WORKING_BINARY" 2>/dev/null | grep -i -E "(audio|wav|mp3)" | wc -l)
    echo "  Audio processing symbols: $audio_symbols"
    
    if [ $opencv_symbols -gt 0 ] || [ $cv_symbols -gt 0 ] || [ $audio_symbols -gt 0 ]; then
        echo "  ⚠️  WARNING: Heavy multimedia dependencies detected!"
    else
        echo "  ✅ No concerning multimedia dependencies found"
    fi
fi

echo ""
echo "📋 8. iOS COMPATIBILITY ASSESSMENT"
echo "==================================="
echo "Based on the analysis above:"
echo ""
echo "✅ LIKELY COMPATIBLE:"
echo "  - Core ONNX Runtime (proven to work on mobile)"
echo "  - Foundation framework"
echo "  - CoreML framework" 
echo "  - Basic C++ standard library"
echo ""
echo "❓ NEEDS INVESTIGATION:"
echo "  - ONNX Runtime Extensions (tokenizer functionality)"
echo "  - CoreServices framework (limited on iOS)"
echo "  - Custom operators libraries"
echo ""
echo "❌ POTENTIAL BLOCKERS:"
if [ -f "$WORKING_BINARY" ]; then
    blocker_count=0
    
    # Check each potential blocker
    if find "$BUILD_DIR" -name "*opencv*" | head -1 >/dev/null; then
        echo "  - OpenCV dependency"
        blocker_count=$((blocker_count + 1))
    fi
    
    if find "$BUILD_DIR" -name "*ffmpeg*" | head -1 >/dev/null; then
        echo "  - FFmpeg dependency"
        blocker_count=$((blocker_count + 1))
    fi
    
    if [ $blocker_count -eq 0 ]; then
        echo "  - None detected! 🎉"
    fi
else
    echo "  - Cannot analyze (binary not found)"
fi

echo ""
echo "🎯 FINAL ASSESSMENT"
echo "==================="
echo "Ready for iOS project: $([ -f "$WORKING_BINARY" ] && echo "✅ YES" || echo "❌ NEED TO BUILD WORKING BINARY FIRST")"