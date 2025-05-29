# Minimal Source Build for Phi-3 C++ Integration
# Step 3: Build everything needed from source

GENAI_ROOT = ../onnxruntime-genai
SRC_ROOT = $(GENAI_ROOT)/src
BUILD_DIR = $(GENAI_ROOT)/build/macOS/RelWithDebInfo
ORT_ROOT = $(BUILD_DIR)

# Compiler settings
CXX = clang++
CXXFLAGS = -std=c++20 -O2 -Wall -fPIC
INCLUDES = -I$(SRC_ROOT) \
           -I$(GENAI_ROOT)/src/ort \
           -I$(BUILD_DIR)/_deps/nlohmann_json-src/include \
           -I$(BUILD_DIR)/_deps/gsl-src/include \
           -I$(BUILD_DIR)/_deps/ortlib-src/build/native/include \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/include \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/shared/api \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/base \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/operators

# System libraries (based on otool output)
SYSTEM_LIBS = -framework Foundation \
              -framework CoreML \
              -framework CoreFoundation \
              -framework CoreGraphics \
              -framework ImageIO \
              -framework CoreServices

# ONNX Runtime library (we still need this)
ORT_LIB = $(BUILD_DIR)/libonnxruntime.dylib
ORT_LIBS = -L$(BUILD_DIR) -lonnxruntime -L$(BUILD_DIR)/lib -lortcustomops -lnoexcep_operators -locos_operators -Wl,-rpath,$(BUILD_DIR)

# ESSENTIAL SOURCE FILES (for basic Phi-3 functionality)
ESSENTIAL_SRCS = \
    $(SRC_ROOT)/ort_genai_c.cpp \
    $(SRC_ROOT)/config.cpp \
    $(SRC_ROOT)/generators.cpp \
    $(SRC_ROOT)/sequences.cpp \
    $(SRC_ROOT)/models/model.cpp \
    $(SRC_ROOT)/models/decoder_only.cpp \
    $(SRC_ROOT)/cpu/interface.cpp \
    $(SRC_ROOT)/json.cpp \
    $(SRC_ROOT)/logging.cpp \
    $(SRC_ROOT)/tensor.cpp \
    $(SRC_ROOT)/search.cpp \
    $(SRC_ROOT)/beam_search_scorer.cpp

# SUPPORTING FILES (needed based on linking errors)
SUPPORTING_SRCS = \
    $(SRC_ROOT)/models/decoder_only_pipeline.cpp \
    $(SRC_ROOT)/models/input_ids.cpp \
    $(SRC_ROOT)/models/kv_cache.cpp \
    $(SRC_ROOT)/models/logits.cpp \
    $(SRC_ROOT)/models/utils.cpp \
    $(SRC_ROOT)/models/env_utils.cpp \
    $(SRC_ROOT)/models/extra_inputs.cpp \
    $(SRC_ROOT)/models/extra_outputs.cpp \
    $(SRC_ROOT)/models/position_inputs.cpp \
    $(SRC_ROOT)/models/whisper.cpp \
    $(SRC_ROOT)/models/multi_modal.cpp \
    $(SRC_ROOT)/models/gpt.cpp \
    $(SRC_ROOT)/models/adapters.cpp \
    $(SRC_ROOT)/models/debugging.cpp \
    $(SRC_ROOT)/models/whisper_processor.cpp \
    $(SRC_ROOT)/models/phi_image_processor.cpp \
    $(SRC_ROOT)/models/phi_multimodal_processor.cpp \
    $(SRC_ROOT)/models/gemma_image_processor.cpp \
    $(SRC_ROOT)/runtime_settings.cpp \
    $(SRC_ROOT)/softmax_cpu.cpp

# ALL SOURCE FILES (essential + supporting)
ALL_MINIMAL_SRCS = $(ESSENTIAL_SRCS) $(SUPPORTING_SRCS)

# Object files
ESSENTIAL_OBJS = $(ESSENTIAL_SRCS:.cpp=.o)
ALL_MINIMAL_OBJS = $(ALL_MINIMAL_SRCS:.cpp=.o)

# Targets
TARGET_ESSENTIAL = test_phi3_minimal_essential
TARGET_FULL_MINIMAL = test_phi3_minimal_full
SOURCE = test_phi3.cpp

# Default target
all: $(TARGET_ESSENTIAL) $(TARGET_FULL_MINIMAL)

# Build with only essential files
$(TARGET_ESSENTIAL): $(ESSENTIAL_OBJS) $(SOURCE)
	@echo "🔨 Building $(TARGET_ESSENTIAL) with essential files only..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET_ESSENTIAL) $(SOURCE) $(ESSENTIAL_OBJS) $(ORT_LIBS) $(SYSTEM_LIBS)
	@echo "✅ Essential build complete!"

# Build with essential + supporting files
$(TARGET_FULL_MINIMAL): $(ALL_MINIMAL_OBJS) $(SOURCE)
	@echo "🔨 Building $(TARGET_FULL_MINIMAL) with all minimal files..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET_FULL_MINIMAL) $(SOURCE) $(ALL_MINIMAL_OBJS) $(ORT_LIBS) $(SYSTEM_LIBS)
	@echo "✅ Full minimal build complete!"

# Compile individual source files
%.o: %.cpp
	@echo "📝 Compiling $<..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Test builds
test-essential: $(TARGET_ESSENTIAL)
	@echo "🚀 Testing essential build..."
	./$(TARGET_ESSENTIAL)

test-full-minimal: $(TARGET_FULL_MINIMAL)
	@echo "🚀 Testing full minimal build..."
	./$(TARGET_FULL_MINIMAL)

# Check what we built
check-deps:
	@echo "🔍 Checking essential build dependencies..."
	@if [ -f "$(TARGET_ESSENTIAL)" ]; then otool -L $(TARGET_ESSENTIAL); fi
	@echo ""
	@echo "🔍 Checking full minimal build dependencies..."  
	@if [ -f "$(TARGET_FULL_MINIMAL)" ]; then otool -L $(TARGET_FULL_MINIMAL); fi

# List source files being used
list-sources:
	@echo "📋 Essential source files ($(words $(ESSENTIAL_SRCS))):"
	@for src in $(ESSENTIAL_SRCS); do echo "  $$src"; done
	@echo ""
	@echo "📋 Supporting source files ($(words $(SUPPORTING_SRCS))):"
	@for src in $(SUPPORTING_SRCS); do echo "  $$src"; done
	@echo ""
	@echo "📊 Total: $(words $(ALL_MINIMAL_SRCS)) files (vs 42 in full build)"

# Clean
clean:
	rm -f $(TARGET_ESSENTIAL) $(TARGET_FULL_MINIMAL)
	find $(SRC_ROOT) -name "*.o" -delete

# Check if all source files exist
check-sources:
	@echo "🔍 Checking if all source files exist..."
	@for src in $(ALL_MINIMAL_SRCS); do \
		if [ ! -f "$$src" ]; then \
			echo "❌ Missing: $$src"; \
		else \
			echo "✅ Found: $$src"; \
		fi; \
	done

.PHONY: all test-essential test-full-minimal check-deps list-sources clean check-sources
