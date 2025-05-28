#!/bin/bash

# Script to find missing source files for the minimal build
GENAI_ROOT="../onnxruntime-genai"

echo "🔍 Searching for missing source files..."
echo "=================================="

# Look for files containing the missing symbols
echo "1. Looking for Embeddings implementations:"
find $GENAI_ROOT/src -name "*.cpp" -exec grep -l "Embeddings::" {} \; 2>/dev/null

echo ""
echo "2. Looking for LoadAudios/LoadImages implementations:"
find $GENAI_ROOT/src -name "*.cpp" -exec grep -l "LoadAudios\|LoadImages" {} \; 2>/dev/null

echo ""
echo "3. Looking for ProcessTensor implementations:"
find $GENAI_ROOT/src -name "*.cpp" -exec grep -l "ProcessTensor" {} \; 2>/dev/null

echo ""
echo "4. Looking for MultiModalFeatures implementations:"
find $GENAI_ROOT/src -name "*.cpp" -exec grep -l "MultiModalFeatures::" {} \; 2>/dev/null

echo ""
echo "5. Looking for device interface implementations:"
find $GENAI_ROOT/src -name "*.cpp" -exec grep -l "GetQNNInterface\|GetWebGPUInterface\|GetOpenVINOInterface" {} \; 2>/dev/null

echo ""
echo "6. Looking for WindowedKeyValueCache implementations:"
find $GENAI_ROOT/src -name "*.cpp" -exec grep -l "WindowedKeyValueCache" {} \; 2>/dev/null

echo ""
echo "7. All .cpp files in src directory:"
find $GENAI_ROOT/src -name "*.cpp" | sort