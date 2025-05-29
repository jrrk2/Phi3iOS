# Minimal Build Makefile - No Duplicates
# Only includes essential files, avoiding duplicate symbols

# Paths
GENAI_ROOT = ../onnxruntime-genai
BUILD_DIR = $(GENAI_ROOT)/build/macOS/RelWithDebInfo
SRC_DIR = $(GENAI_ROOT)/src

# Compiler settings
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

# Library paths
LIBS = -L$(BUILD_DIR) -lonnxruntime \
       -L$(BUILD_DIR)/lib -lortcustomops -lnoexcep_operators -locos_operators \
       -Wl,-rpath,$(BUILD_DIR) \
       -framework Foundation -framework CoreML -framework CoreFoundation \
       -framework CoreGraphics -framework ImageIO -framework CoreServices

# Essential source files (your original working set)
ESSENTIAL_SOURCES = $(SRC_DIR)/ort_genai_c.cpp \
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

# Model sources (avoiding duplicates)
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
                $(SRC_DIR)/models/debugging.cpp

# Missing source files (that we found were needed)
MISSING_SOURCES = $(SRC_DIR)/models/embeddings.cpp \
                  $(SRC_DIR)/models/multi_modal_features.cpp \
                  $(SRC_DIR)/models/processor.cpp \
                  $(SRC_DIR)/models/windowed_kv_cache.cpp \
                  $(SRC_DIR)/models/threadpool.cpp

# Processor sources (needed for vtables - even if not using multimodal)
PROCESSOR_SOURCES = $(SRC_DIR)/models/whisper_processor.cpp \
                    $(SRC_DIR)/models/phi_image_processor.cpp \
                    $(SRC_DIR)/models/phi_multimodal_processor.cpp \
                    $(SRC_DIR)/models/gemma_image_processor.cpp

# CPU interface + stubs for missing device interfaces
CPU_SOURCES = $(SRC_DIR)/cpu/interface.cpp

# Essential sources (includes processors for vtables)
MINIMAL_SOURCES = $(ESSENTIAL_SOURCES) \
                  $(MODEL_SOURCES) \
                  $(MISSING_SOURCES) \
                  $(PROCESSOR_SOURCES) \
                  $(CPU_SOURCES)

# Add processors only if you need multimodal functionality
FULL_SOURCES = $(MINIMAL_SOURCES) $(PROCESSOR_SOURCES)

# Object files for minimal build
MINIMAL_OBJECTS = $(MINIMAL_SOURCES:.cpp=.o)

# Object files for full build
FULL_OBJECTS = $(FULL_SOURCES:.cpp=.o)

# Targets
TARGET_MINIMAL = test_phi3_minimal
TARGET_FULL = test_phi3_full
SOURCE = test_phi3.cpp

.PHONY: all clean test-minimal test-full minimal full

# Default: try minimal first
all: minimal

# Minimal build (just essential + missing files)
minimal: $(TARGET_MINIMAL)

# Full build (includes processors)
full: $(TARGET_FULL)

# Compile individual object files
%.o: %.cpp
	@echo "📝 Compiling $<..."
	@if [ -f "$<" ]; then \
		$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@; \
	else \
		echo "⚠️  Skipping missing file: $<"; \
	fi

# Build minimal version
$(TARGET_MINIMAL): $(MINIMAL_OBJECTS)
	@echo "🔨 Building $(TARGET_MINIMAL) (minimal static build)..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET_MINIMAL) $(SOURCE) $(MINIMAL_OBJECTS) device_interface_stubs.cpp $(LIBS)
	@echo "✅ Minimal build complete!"

# Build full version
$(TARGET_FULL): $(FULL_OBJECTS)
	@echo "🔨 Building $(TARGET_FULL) (full static build)..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET_FULL) $(SOURCE) $(FULL_OBJECTS) $(LIBS)
	@echo "✅ Full build complete!"

# Test builds
test-minimal: $(TARGET_MINIMAL)
	@echo "🚀 Testing minimal build..."
	./$(TARGET_MINIMAL)

test-full: $(TARGET_FULL)
	@echo "🚀 Testing full build..."
	./$(TARGET_FULL)

# Check what files exist
check-files:
	@echo "🔍 Checking source files..."
	@echo "MISSING FILES:"
	@for src in $(MISSING_SOURCES); do \
		if [ ! -f "$$src" ]; then \
			echo "❌ $$src"; \
		else \
			echo "✅ $$src"; \
		fi; \
	done
	@echo "\nPROCESSOR FILES:"
	@for src in $(PROCESSOR_SOURCES); do \
		if [ ! -f "$$src" ]; then \
			echo "❌ $$src"; \
		else \
			echo "✅ $$src"; \
		fi; \
	done

# Clean
clean:
	rm -f $(TARGET_MINIMAL) $(TARGET_FULL)
	find $(SRC_DIR) -name "*.o" -delete

# If minimal build works, create iOS version
ios-prepare: minimal
	@echo "📱 Preparing for iOS build..."
	@echo "Minimal build succeeded! Ready to adapt for iOS."
	@echo ""
	@echo "Next steps:"
	@echo "1. Test: make -f minimal_no_duplicates.mk test-minimal"
	@echo "2. If working, adapt compiler flags for iOS"
	@echo "3. Replace dynamic libraries with static iOS libraries"