# Clean iOS-Compatible Static ONNX Runtime GenAI Build
# Uses separate artifact files - no embedded code generation

# Configuration
GENAI_ROOT = ../onnxruntime-genai
BUILD_DIR = $(GENAI_ROOT)/build/macOS/RelWithDebInfo
SRC_DIR = $(GENAI_ROOT)/src
EXT_SRC_DIR = $(BUILD_DIR)/_deps/onnxruntime_extensions-src

# Compiler settings for static linking
CXX = clang++
CC = clang  
CXXFLAGS = -std=c++20 -O2 -Wall -fPIC -DTEXT_ONLY_BUILD=1 -DSTATIC_BUILD=1
CFLAGS = -std=c11 -O2 -Wall -fPIC

# Include paths
INCLUDES = -I$(SRC_DIR) \
           -I$(BUILD_DIR)/_deps/nlohmann_json-src/include \
           -I$(BUILD_DIR)/_deps/gsl-src/include \
           -I$(BUILD_DIR)/_deps/ortlib-src/build/native/include \
           -I$(EXT_SRC_DIR)/include \
           -I$(EXT_SRC_DIR)/shared/api \
           -I$(EXT_SRC_DIR)/base

# Libraries (dynamic for now, will make static later)
LIBS = -L$(BUILD_DIR) -lonnxruntime \
       -Wl,-rpath,$(BUILD_DIR) \
       -framework Foundation -framework CoreML -framework Accelerate

# Core GenAI sources (essential for text generation)
GENAI_ESSENTIAL = $(SRC_DIR)/config.cpp \
                  $(SRC_DIR)/generators.cpp \
                  $(SRC_DIR)/sequences.cpp \
                  $(SRC_DIR)/logging.cpp \
                  $(SRC_DIR)/tensor.cpp \
                  $(SRC_DIR)/search.cpp \
                  $(SRC_DIR)/beam_search_scorer.cpp

# Model sources - use existing model_text_only.cpp
MODEL_SOURCES = $(SRC_DIR)/models/model_text_only.cpp \
                $(SRC_DIR)/models/decoder_only.cpp \
                $(SRC_DIR)/models/input_ids.cpp \
                $(SRC_DIR)/models/kv_cache.cpp \
                $(SRC_DIR)/models/logits.cpp \
                $(SRC_DIR)/models/utils.cpp \
                $(SRC_DIR)/models/env_utils.cpp \
                $(SRC_DIR)/models/extra_inputs.cpp \
                $(SRC_DIR)/models/extra_outputs.cpp \
                $(SRC_DIR)/models/position_inputs.cpp \
                $(SRC_DIR)/models/gpt.cpp

# CPU interface
CPU_SOURCES = $(SRC_DIR)/cpu/interface.cpp

# Essential tokenizer components
TOKENIZER_SOURCES = $(EXT_SRC_DIR)/base/string_utils.cc

# Check which files exist
EXISTING_GENAI = $(foreach src,$(GENAI_ESSENTIAL),$(if $(wildcard $(src)),$(src)))
EXISTING_MODEL = $(foreach src,$(MODEL_SOURCES),$(if $(wildcard $(src)),$(src)))
EXISTING_CPU = $(foreach src,$(CPU_SOURCES),$(if $(wildcard $(src)),$(src)))
EXISTING_TOKENIZER = $(foreach src,$(TOKENIZER_SOURCES),$(if $(wildcard $(src)),$(src)))

# All source files we'll compile
ALL_SOURCES = $(EXISTING_GENAI) $(EXISTING_MODEL) $(EXISTING_CPU) $(EXISTING_TOKENIZER)

# Implementation files (created as separate artifacts)
MISSING_FUNCS = missing_functions.cpp
WORKING_TOKENIZER = working_tokenizer.cpp
STATIC_TEST = static_test.cpp
FUNCTIONAL_DEMO = functional_demo.cpp
C_API_DEMO = working_c_api_demo.cpp

# Targets
TARGET = genai_static_clean
DEMO_TARGET = genai_functional_demo
C_API_TARGET = genai_c_api_demo
SOURCE = $(STATIC_TEST)

.PHONY: all clean check-sources test-build demo c-demo help

all: check-requirements $(TARGET)

demo: check-requirements $(DEMO_TARGET)

c-demo: check-requirements $(C_API_TARGET)

# Check requirements before building
check-requirements:
	@echo "🔍 Checking build requirements..."
	@echo "GenAI core: $(words $(EXISTING_GENAI))/$(words $(GENAI_ESSENTIAL))"
	@echo "Model files: $(words $(EXISTING_MODEL))/$(words $(MODEL_SOURCES))"
	@echo "CPU files: $(words $(EXISTING_CPU))/$(words $(CPU_SOURCES))"
	@echo "Tokenizer: $(words $(EXISTING_TOKENIZER))/$(words $(TOKENIZER_SOURCES))"
	@echo "📊 Total available: $(words $(ALL_SOURCES)) source files"
	@echo ""
	@if [ ! -f "$(MISSING_FUNCS)" ]; then \
		echo "❌ Missing $(MISSING_FUNCS)"; \
		echo "💡 Please create this file using the 'Missing Functions Implementation' artifact"; \
		exit 1; \
	fi
	@if [ ! -f "$(WORKING_TOKENIZER)" ]; then \
		echo "❌ Missing $(WORKING_TOKENIZER)"; \
		echo "💡 Please create this file using the 'Working Tokenizer Implementation' artifact"; \
		exit 1; \
	fi
	@if [ ! -f "$(STATIC_TEST)" ]; then \
		echo "❌ Missing $(STATIC_TEST)"; \
		echo "💡 Please create this file using the 'Static Test Program' artifact"; \
		exit 1; \
	fi
	@if [ ! -f "$(FUNCTIONAL_DEMO)" ]; then \
		echo "❌ Missing $(FUNCTIONAL_DEMO)"; \
		echo "💡 Please create this file using the 'Functional GenAI Demo' artifact"; \
		exit 1; \
	fi
	@if [ ! -f "$(C_API_DEMO)" ]; then \
		echo "⚠️  Missing $(C_API_DEMO)"; \
		echo "💡 Please create this file using the 'Working C API Demo' artifact"; \
	fi
	@echo "✅ All required files present"

# Check which sources are available
check-sources:
	@echo "🔍 Available source files:"
	@for src in $(GENAI_ESSENTIAL) $(MODEL_SOURCES) $(CPU_SOURCES) $(TOKENIZER_SOURCES); do \
		if [ -f "$$src" ]; then \
			echo "✅ $$src"; \
		else \
			echo "❌ $$src"; \
		fi; \
	done

# Build the clean static version
$(TARGET): check-requirements
	@echo "🔨 Building clean static GenAI..."
	@echo "📦 Using separate implementation files"
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET) $(SOURCE) \
		$(ALL_SOURCES) $(MISSING_FUNCS) $(WORKING_TOKENIZER) $(LIBS)
# Build the functional demo
$(DEMO_TARGET): check-requirements
	@echo "🔨 Building functional GenAI demo..."
	@echo "📦 Using ONNX Runtime GenAI API"
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(DEMO_TARGET) $(FUNCTIONAL_DEMO) \
		$(ALL_SOURCES) $(MISSING_FUNCS) $(WORKING_TOKENIZER) $(LIBS)
	@if [ -f $(DEMO_TARGET) ]; then \
		echo "✅ Functional demo build successful!"; \
		echo "🍎 Executable: $(DEMO_TARGET)"; \
		echo "📊 Size: $(du -h $(DEMO_TARGET) | cut -f1)"; \
		echo ""; \
		echo "🚀 Try running:"; \
		echo "  ./$(DEMO_TARGET) your_model.onnx interactive"; \
		echo "  ./$(DEMO_TARGET) your_model.onnx benchmark"; \
		echo "  ./$(DEMO_TARGET) your_model.onnx single \"What is AI?\""; \
# Build the C API demo (more stable)
$(C_API_TARGET): check-requirements
	@echo "🔨 Building C API GenAI demo..."
	@echo "📦 Using stable C API instead of C++ wrapper"
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(C_API_TARGET) $(C_API_DEMO) \
		$(ALL_SOURCES) $(MISSING_FUNCS) $(WORKING_TOKENIZER) $(LIBS)
	@if [ -f $(C_API_TARGET) ]; then \
		echo "✅ C API demo build successful!"; \
		echo "🍎 Executable: $(C_API_TARGET)"; \
		echo "📊 Size: $(du -h $(C_API_TARGET) | cut -f1)"; \
		echo ""; \
		echo "🚀 Try running:"; \
		echo "  ./$(C_API_TARGET) your_model.onnx interactive"; \
		echo "  ./$(C_API_TARGET) your_model.onnx benchmark"; \
		echo "  ./$(C_API_TARGET) your_model.onnx single \"What is AI?\""; \
		echo ""; \
		echo "💡 This uses the stable C API - should work better!"; \
	else \
		echo "❌ C API demo build failed"; \
	fi

# Test the build
test-build: $(TARGET)
	@echo "🧪 Testing clean static build..."
	@echo "Dependencies:"
	@otool -L $(TARGET) | head -10
	@echo ""
	@echo "Running test:"
	@./$(TARGET) test_model_path

# Show what files are needed
show-requirements:
	@echo "📋 Required Files for Clean Build:"
	@echo ""
	@echo "Source files from ONNX Runtime GenAI:"
	@echo "$(words $(ALL_SOURCES)) files (checked automatically)"
	@echo ""
	@echo "Implementation files (create from artifacts):"
	@echo "  $(MISSING_FUNCS) - Use 'Missing Functions Implementation' artifact"
	@echo "  $(WORKING_TOKENIZER) - Use 'Working Tokenizer Implementation' artifact" 
	@echo "  $(STATIC_TEST) - Use 'Static Test Program' artifact"
	@echo ""
	@echo "🎯 Save each artifact as the corresponding filename"

# Clean build files
clean:
	rm -f $(TARGET)
	@echo "🧹 Cleaned build files"
	@echo "💡 Implementation files preserved ($(MISSING_FUNCS), $(WORKING_TOKENIZER), $(STATIC_TEST))"

# Clean everything including implementation files
clean-all:
	rm -f $(TARGET) $(MISSING_FUNCS) $(WORKING_TOKENIZER) $(STATIC_TEST)
	@echo "🧹 Cleaned all files including implementations"

# Help
help:
	@echo "📖 Clean Static Build Targets:"
	@echo "  all               - Build clean static executable"
	@echo "  demo              - Build functional GenAI demo"
	@echo "  test-build        - Test the built executable"
	@echo "  check-sources     - Check available source files"
	@echo "  check-requirements - Check all build requirements"
	@echo "  show-requirements - Show what files are needed"
	@echo "  clean             - Remove build files (keep implementations)"
	@echo "  clean-all         - Remove all files including implementations"
	@echo "  help              - Show this help"
	@echo ""
	@echo "🍎 Clean approach: uses separate artifact files, no embedded code"
	@echo "🚀 Try: make demo && ./genai_functional_demo your_model.onnx"