# iOS Static Build Makefile for ONNX Runtime GenAI
# This includes ALL necessary source files for static linking

# Paths
GENAI_ROOT = ../onnxruntime-genai
BUILD_DIR = $(GENAI_ROOT)/build/macOS/RelWithDebInfo
SRC_DIR = $(GENAI_ROOT)/src

# Compiler settings for iOS compatibility
CXX = clang++
CXXFLAGS = -std=c++20 -O2 -Wall -fPIC

# Include paths
INCLUDES = -I$(SRC_DIR) \
           -I$(SRC_DIR)/ort \
           -I$(BUILD_DIR)/_deps/nlohmann_json-src/include \
           -I$(BUILD_DIR)/_deps/gsl-src/include \
           -I$(BUILD_DIR)/_deps/ortlib-src/build/native/include \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/include \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/shared/api \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/base \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/operators

# Library paths (for macOS testing - will need adjustment for iOS)
LIBS = -L$(BUILD_DIR) -lonnxruntime \
       -L$(BUILD_DIR)/lib -lortcustomops -lnoexcep_operators -locos_operators \
       -Wl,-rpath,$(BUILD_DIR) \
       -framework Foundation -framework CoreML -framework CoreFoundation \
       -framework CoreGraphics -framework ImageIO -framework CoreServices

# Core source files
CORE_SOURCES = $(SRC_DIR)/ort_genai_c.cpp \
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

# Model source files (including the missing ones)
MODEL_SOURCES = $(SRC_DIR)/models/model.cpp \
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
                $(SRC_DIR)/models/whisper.cpp \
                $(SRC_DIR)/models/multi_modal.cpp \
                $(SRC_DIR)/models/gpt.cpp \
                $(SRC_DIR)/models/adapters.cpp \
                $(SRC_DIR)/models/debugging.cpp \
                $(SRC_DIR)/models/threadpool.cpp \

# Previously missing files that we found
MISSING_SOURCES = $(SRC_DIR)/models/embeddings.cpp \
                  $(SRC_DIR)/models/multi_modal_features.cpp \
                  $(SRC_DIR)/models/processor.cpp \
                  $(SRC_DIR)/models/windowed_kv_cache.cpp

# Processor source files
PROCESSOR_SOURCES = $(SRC_DIR)/models/whisper_processor.cpp \
                    $(SRC_DIR)/models/phi_image_processor.cpp \
                    $(SRC_DIR)/models/phi_multimodal_processor.cpp \
                    $(SRC_DIR)/models/gemma_image_processor.cpp

# CPU interface (required for iOS)
CPU_SOURCES = $(SRC_DIR)/cpu/interface.cpp

# Device interface sources (these provide the missing GetXXXInterface functions)
# Note: For iOS, we only need CPU, but including others for completeness
DEVICE_SOURCES = $(SRC_DIR)/webgpu/interface.cpp \
                 $(SRC_DIR)/openvino/interface.cpp \
                 $(SRC_DIR)/qnn/interface.cpp

# Combine all sources
ALL_SOURCES = $(CORE_SOURCES) \
              $(MODEL_SOURCES) \
              $(MISSING_SOURCES) \
              $(PROCESSOR_SOURCES) \
              $(CPU_SOURCES) \
              $(DEVICE_SOURCES)

# Object files
OBJECTS = $(ALL_SOURCES:.cpp=.o)

# Targets
TARGET_STATIC = test_phi3_ios_static
SOURCE = test_phi3.cpp

.PHONY: all clean test-static check-sources ios-prepare

all: check-sources $(TARGET_STATIC)

# Check which sources actually exist
check-sources:
	@echo "🔍 Checking source files..."
	@echo "=================================="
	@missing_count=0; \
	for src in $(ALL_SOURCES); do \
		if [ -f "$$src" ]; then \
			echo "✅ $$src"; \
		else \
			echo "❌ $$src (MISSING)"; \
			missing_count=$$((missing_count + 1)); \
		fi; \
	done; \
	echo ""; \
	echo "📊 Summary: $$missing_count missing files out of $(words $(ALL_SOURCES)) total"

# Compile individual object files
%.o: %.cpp
	@echo "📝 Compiling $<..."
	@if [ -f "$<" ]; then \
		$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@; \
	else \
		echo "⚠️  Skipping missing file: $<"; \
	fi

# Build the test executable (static version)
$(TARGET_STATIC): $(OBJECTS)
	@echo "🔨 Building $(TARGET_STATIC) with static linking..."
	@existing_objects=""; \
	for obj in $(OBJECTS); do \
		if [ -f "$$obj" ]; then \
			existing_objects="$$existing_objects $$obj"; \
		fi; \
	done; \
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET_STATIC) $(SOURCE) $$existing_objects $(LIBS)
	@echo "✅ Static build complete!"

# Test the build
test-static: $(TARGET_STATIC)
	@echo "🚀 Testing static build..."
	./$(TARGET_STATIC)

# Clean
clean:
	rm -f $(TARGET_STATIC)
	find $(SRC_DIR) -name "*.o" -delete

# iOS preparation steps
ios-prepare:
	@echo "📱 iOS Preparation Checklist:"
	@echo "=================================="
	@echo "1. ✅ Source files identified and included"
	@echo "2. 🔄 Next: Configure for iOS SDK"
	@echo "3. 🔄 Next: Replace macOS frameworks with iOS equivalents"
	@echo "4. 🔄 Next: Update library paths for iOS static libraries"
	@echo ""
	@echo "📋 Required changes for iOS:"
	@echo "  - Change SDK: -isysroot \$$(xcrun --sdk iphoneos --show-sdk-path)"
	@echo "  - Target iOS: -target arm64-apple-ios12.0"
	@echo "  - Static libs: Use .a files instead of .dylib"
	@echo "  - Remove: -Wl,-rpath (not needed for static)"
	@echo ""
	@echo "🔧 To convert this for iOS, run:"
	@echo "  make -f ios_static_build.mk ios-config"

# Generate iOS-specific configuration
ios-config:
	@echo "📱 Generating iOS-specific makefile..."
	@sed 's/clang++/xcrun -sdk iphoneos clang++/g; \
	      s/-Wl,-rpath[^[:space:]]*//' ios_static_build.mk > ios_static_build_ios.mk
	@echo "# iOS-specific additions" >> ios_static_build_ios.mk
	@echo "CXXFLAGS += -target arm64-apple-ios12.0" >> ios_static_build_ios.mk
	@echo "CXXFLAGS += -isysroot \$$(xcrun --sdk iphoneos --show-sdk-path)" >> ios_static_build_ios.mk
	@echo "✅ Created ios_static_build_ios.mk for iOS development"

# Alternative: Create a source list for Xcode
xcode-sources:
	@echo "📋 Source files for Xcode project:"
	@echo "=================================="
	@for src in $(ALL_SOURCES); do \
		if [ -f "$$src" ]; then \
			echo "$$src"; \
		fi; \
	done > xcode_sources.txt
	@echo "✅ Created xcode_sources.txt - add these files to your Xcode project"
