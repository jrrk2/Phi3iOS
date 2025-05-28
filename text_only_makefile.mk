# Text-Only ONNX Runtime GenAI Makefile for macOS
# Excludes all multimodal components to avoid missing symbol issues

# Configuration
GENAI_ROOT = ../onnxruntime-genai
BUILD_DIR = $(GENAI_ROOT)/build/macOS/RelWithDebInfo
SRC_DIR = $(GENAI_ROOT)/src
EXT_SRC_DIR = $(BUILD_DIR)/_deps/onnxruntime_extensions-src

# Compiler
CXX = clang++
CC = clang
CXXFLAGS = -std=c++20 -O2 -Wall -fPIC -DTEXT_ONLY_BUILD=1 -fvisibility=default
CFLAGS = -std=c11 -O2 -Wall -fPIC

# Include paths (essential only)
INCLUDES = -I$(SRC_DIR) \
           -I$(SRC_DIR)/ort \
           -I$(BUILD_DIR)/_deps/nlohmann_json-src/include \
           -I$(BUILD_DIR)/_deps/gsl-src/include \
           -I$(BUILD_DIR)/_deps/ortlib-src/build/native/include \
           -I$(EXT_SRC_DIR)/include \
           -I$(EXT_SRC_DIR)/shared/api \
           -I$(EXT_SRC_DIR)/base \
           -I$(EXT_SRC_DIR)/operators/tokenizer \
           -I$(EXT_SRC_DIR)

# Libraries
LIBS = -L$(BUILD_DIR) -lonnxruntime \
       -Wl,-rpath,$(BUILD_DIR) \
       -framework Foundation -framework CoreML -framework CoreFoundation

# Core GenAI sources (text-only essentials)
GENAI_CORE = $(SRC_DIR)/ort_genai_c.cpp \
             $(SRC_DIR)/config.cpp \
             $(SRC_DIR)/generators.cpp \
             $(SRC_DIR)/sequences.cpp \
             $(SRC_DIR)/json.cpp \
             $(SRC_DIR)/logging.cpp \
             $(SRC_DIR)/tensor.cpp \
             $(SRC_DIR)/search.cpp \
             $(SRC_DIR)/beam_search_scorer.cpp \
             $(SRC_DIR)/runtime_settings.cpp \
             $(SRC_DIR)/softmax_cpu.cpp \
             $(SRC_DIR)/constrained_logits_processor.cpp

# Model sources (text-only - use your custom model file)
GENAI_MODELS = $(SRC_DIR)/models/model_text_only.cpp \
               $(SRC_DIR)/models/decoder_only.cpp \
               $(SRC_DIR)/models/decoder_only_pipeline.cpp \
               $(SRC_DIR)/models/input_ids.cpp \
               $(SRC_DIR)/models/kv_cache.cpp \
               $(SRC_DIR)/models/logits.cpp \
               $(SRC_DIR)/models/utils.cpp \
               $(SRC_DIR)/models/env_utils.cpp \
               $(SRC_DIR)/models/extra_inputs.cpp \
               $(SRC_DIR)/models/extra_outputs.cpp \
               $(SRC_DIR)/models/position_inputs.cpp \
               $(SRC_DIR)/models/gpt.cpp \
               $(SRC_DIR)/models/adapters.cpp \
               $(SRC_DIR)/models/debugging.cpp

# Optional model files (check if they exist)
OPTIONAL_MODELS = $(SRC_DIR)/models/embeddings.cpp \
                  $(SRC_DIR)/models/threadpool.cpp

# CPU interface
CPU_INTERFACE = $(SRC_DIR)/cpu/interface.cpp

# Essential tokenizer (MINIMAL - only what actually works)
WORKING_TOKENIZER = $(EXT_SRC_DIR)/base/string_utils.cc

# Check which files exist and can actually be used
VERIFIED_TOKENIZER = $(foreach src,$(WORKING_TOKENIZER),$(if $(wildcard $(src)),$(src)))

# Check which optional files exist
EXISTING_OPTIONAL = $(foreach src,$(OPTIONAL_MODELS),$(if $(wildcard $(src)),$(src)))

# Final minimal source list (exclude problematic files)
TEXT_SOURCES = $(GENAI_CORE) $(GENAI_MODELS) $(EXISTING_OPTIONAL) $(CPU_INTERFACE) $(WORKING_TOKENIZER)

# Missing implementations file
MISSING_IMPL = missing_implementations.cpp

# Stub file for missing functions (should exist as separate file)
STUB_FILE = complete_device_stubs.cpp

# Missing implementations file for runtime functionality
MISSING_IMPL = missing_implementations.cpp

# Targets
TARGET = phi3_text_only
SOURCE = test_phi3.cpp

.PHONY: all clean check-files test install-deps

all: check-files $(TARGET)

# Use existing text-only stubs file (should be created separately)

# Check source files
check-files:
	@echo "🔍 Checking text-only source files..."
	@total=0; found=0; missing=0; \
	for src in $(TEXT_SOURCES); do \
		total=$((total + 1)); \
		if [ -f "$src" ]; then \
			found=$((found + 1)); \
		else \
			echo "❌ Missing: $src"; \
			missing=$((missing + 1)); \
		fi; \
	done; \
	echo "📊 Text-only files: $found found, $missing missing, $total total"; \
	if [ $missing -gt 5 ]; then \
		echo "⚠️  Too many missing files. Please check your GenAI build."; \
	fi
	@if [ -f "$(SRC_DIR)/models/model_text_only.cpp" ]; then \
		echo "✅ Found your custom model_text_only.cpp"; \
	else \
		echo "❌ Missing your custom model_text_only.cpp file"; \
		echo "💡 Please ensure this file exists at $(SRC_DIR)/models/model_text_only.cpp"; \
	fi
	@if [ -f "$(MISSING_IMPL)" ]; then \
		echo "✅ Found missing implementations file"; \
	else \
		echo "❌ Missing $(MISSING_IMPL) file"; \
		echo "💡 Please create this file with the 'Missing Function Implementations' artifact"; \
	fi

# Compile with direct source inclusion (avoid object file issues)
$(TARGET): check-files
	@echo "🔨 Building text-only GenAI demo..."
	@echo "📝 Using your custom model_text_only.cpp file..."
	@if [ ! -f "$(STUB_FILE)" ]; then \
		echo "❌ Missing $(STUB_FILE) - please create this file with the device stubs"; \
		echo "💡 You can use the artifact 'Complete Device Interface Stubs' as a template"; \
		exit 1; \
	fi
	@if [ ! -f "$(MISSING_IMPL)" ]; then \
		echo "❌ Missing $(MISSING_IMPL) - please create this file"; \
		echo "💡 Use the artifact 'Missing Function Implementations'"; \
		exit 1; \
	fi
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET) $(SOURCE) \
		$(TEXT_SOURCES) $(STUB_FILE) $(MISSING_IMPL) $(LIBS) \
		2>&1 | grep -v "warning:" || true
	@if [ -f $(TARGET) ]; then \
		echo "✅ Text-only build successful!"; \
		echo "🚀 Run with: ./$(TARGET) <model_path>"; \
	else \
		echo "❌ Build failed. Check dependencies."; \
	fi

# Test the build
test: $(TARGET)
	@echo "🧪 Testing text-only build..."
	@if [ -f $(TARGET) ]; then \
		echo "✅ Executable created successfully!"; \
		file $(TARGET); \
		otool -L $(TARGET) | head -10; \
	else \
		echo "❌ No executable found"; \
	fi

# Check dependencies
install-deps:
	@echo "📦 Checking dependencies..."
	@echo "GenAI root: $(GENAI_ROOT)"
	@echo "Build dir: $(BUILD_DIR)"
	@if [ ! -d "$(GENAI_ROOT)" ]; then \
		echo "❌ GenAI source not found"; \
		echo "Please clone: git clone https://github.com/microsoft/onnxruntime-genai.git"; \
	else \
		echo "✅ GenAI source found"; \
	fi
	@if [ ! -f "$(BUILD_DIR)/libonnxruntime.dylib" ]; then \
		echo "❌ ONNX Runtime not built"; \
		echo "Please build: cd onnxruntime-genai && ./build.sh --config RelWithDebInfo"; \
	else \
		echo "✅ ONNX Runtime library found"; \
	fi

# Download a test model
download-model:
	@echo "📥 Downloading Phi-3 Mini model..."
	@if [ ! -d "phi3-mini-4k-instruct-onnx" ]; then \
		echo "Downloading from Hugging Face..."; \
		git clone https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-onnx phi3-mini-4k-instruct-onnx || \
		echo "❌ Download failed. Please download manually from:"; \
		echo "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-onnx"; \
	else \
		echo "✅ Model already exists"; \
	fi

# Clean
clean:
	rm -f $(TARGET)
	@echo "🧹 Cleaned build files (kept $(STUB_FILE) as it should be maintained separately)"

# Show configuration
show-config:
	@echo "📋 Text-Only Build Configuration:"
	@echo "GenAI core: $(words $(GENAI_CORE)) files"
	@echo "GenAI models: $(words $(GENAI_MODELS)) files"
	@echo "Custom ops: $(words $(CUSTOM_OPS)) files"
	@echo "Optional: $(words $(EXISTING_OPTIONAL)) files"
	@echo "Total: $(words $(TEXT_SOURCES)) files"
	@echo ""
	@echo "🎯 Excludes all multimodal/image/audio processing"
	@echo "✅ Perfect for text-only AI demos on macOS/iOS"

# Help
help:
	@echo "📖 Available targets:"
	@echo "  all          - Build text-only demo (default)"
	@echo "  test         - Test the built executable"
	@echo "  check-files  - Verify source file availability"
	@echo "  install-deps - Check dependencies"
	@echo "  download-model - Download test model"
	@echo "  show-config  - Show build configuration"
	@echo "  debug-symbols - Debug undefined symbols (demangled)"
	@echo "  debug-mangled - Debug undefined symbols (mangled names)"
	@echo "  debug-compare - Compare mangled vs demangled symbols"
	@echo "  build-mangled-errors - Build with raw mangled linker errors"
	@echo "  build-save-errors - Save linker errors to file for analysis"
	@echo "  extract-mangled - Extract mangled symbols from saved errors"
	@echo "  clean        - Remove build files"
	@echo "  help         - Show this help"

# Debug symbols (helpful for troubleshooting)
debug-symbols:
	@echo "🔍 Debugging symbols..."
	@echo "Checking object files for undefined symbols:"
	@for src in $(TEXT_SOURCES); do \
		obj=${src%.cpp}.o; \
		obj=${obj%.cc}.o; \
		if [ -f "$obj" ]; then \
			echo "--- $obj ---"; \
			nm -u "$obj" 2>/dev/null | head -5 || echo "No undefined symbols"; \
		fi; \
	done
	@if [ -f $(TARGET) ]; then \
		echo "--- Final executable ---"; \
		nm -u $(TARGET) 2>/dev/null | head -10 || echo "No undefined symbols in executable"; \
	fi