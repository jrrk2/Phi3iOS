#!/bin/bash
# Script to identify minimal source files needed for Phi-3 C++ integration

echo "🔍 Analyzing ONNX Runtime GenAI source files..."

GENAI_ROOT="../onnxruntime-genai"
SRC_ROOT="$GENAI_ROOT/src"

echo ""
echo "📁 Core source files (root level):"
find "$SRC_ROOT" -maxdepth 1 -name "*.cpp" | grep -v python | sort

echo ""
echo "📁 CPU interface files:"
find "$SRC_ROOT/cpu" -name "*.cpp" | sort

echo ""
echo "📁 Model implementation files:"
find "$SRC_ROOT/models" -name "*.cpp" | head -15

echo ""
echo "📁 Essential headers:"
find "$SRC_ROOT" -maxdepth 1 -name "*.h" | grep -E "(ort_genai|config|generators|sequences)" | sort

echo ""
echo "🎯 Files likely needed for basic Phi-3 functionality:"
echo "ESSENTIAL:"
echo "  - $SRC_ROOT/ort_genai_c.cpp (C API)"
echo "  - $SRC_ROOT/config.cpp (model config)"
echo "  - $SRC_ROOT/generators.cpp (token generation)"
echo "  - $SRC_ROOT/sequences.cpp (token sequences)"
echo "  - $SRC_ROOT/models/model.cpp (model loading)"
echo "  - $SRC_ROOT/models/decoder_only.cpp (for Phi-3)"
echo "  - $SRC_ROOT/cpu/interface.cpp (CPU backend)"

echo ""
echo "SUPPORTING:"
echo "  - $SRC_ROOT/json.cpp (config parsing)"
echo "  - $SRC_ROOT/logging.cpp (error handling)"  
echo "  - $SRC_ROOT/tensor.cpp (tensor operations)"
echo "  - $SRC_ROOT/search.cpp (token search)"
echo "  - $SRC_ROOT/beam_search_scorer.cpp (generation)"

echo ""
echo "📊 Total files analysis:"
total_cpp=$(find "$SRC_ROOT" -name "*.cpp" | grep -v cuda | grep -v dml | grep -v python | grep -v java | grep -v csharp | grep -v objectivec | wc -l)
essential_count=12
echo "  - Total C++ files: $total_cpp"
echo "  - Essential files (estimated): $essential_count"
echo "  - Reduction: ~$((total_cpp - essential_count)) files can potentially be excluded"

echo ""
echo "🧪 Next step: Create source-based build to test this theory"