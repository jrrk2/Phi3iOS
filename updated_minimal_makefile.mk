# Updated Minimal Build Makefile for macOS Phi-3 C++ Test
# This includes additional source files that were missing

# Paths
GENAI_ROOT = ../onnxruntime-genai
BUILD_DIR = $(GENAI_ROOT)/build/macOS/RelWithDebInfo
SRC_DIR = $(GENAI_ROOT)/src

# Compiler settings
CXX = clang++
CXXFLAGS = -std=c++20 -O2 -Wall -fPIC

# Include paths (same as before)
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

# Core source files (keeping your existing ones)
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
               $(SRC_DIR)/softmax_cpu.cpp

# Model source files (keeping your existing ones)
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

# Processor source files (keeping your existing ones)
PROCESSOR_SOURCES = $(SRC_DIR)/models/whisper_processor.cpp \
                    $(SRC_DIR)/models/phi_image_processor.cpp \
                    $(SRC_DIR)/models/phi_multimodal_processor.cpp \
                    $(SRC_DIR)/models/gemma_image_processor.cpp

# Additional sources that might be missing - these need to be found
ADDITIONAL_SOURCES = $(SRC_DIR)/cpu/interface.cpp

# Check if these files exist and add them if they do
EMBEDDINGS_SRC = $(wildcard $(SRC_DIR)/models/embeddings.cpp)
MULTIMODAL_FEATURES_SRC = $(wildcard $(SRC_DIR)/models/multimodal_features.cpp)
AUDIO_SRC = $(wildcard $(SRC_DIR)/models/audio*.cpp)
IMAGE_SRC = $(wildcard $(SRC_DIR)/models/image*.cpp)
DEVICE_INTERFACE_SRC = $(wildcard $(SRC_DIR)/*/device_interface.cpp)
CACHE_SRC = $(wildcard $(SRC_DIR)/models/*cache*.cpp)

# Combine all sources
ALL_SOURCES = $(CORE_SOURCES) $(MODEL_SOURCES) $(PROCESSOR_SOURCES) $(ADDITIONAL_SOURCES)
ALL_SOURCES += $(EMBEDDINGS_SRC) $(MULTIMODAL_FEATURES_SRC) $(AUDIO_SRC) $(IMAGE_SRC)
ALL_SOURCES += $(DEVICE_INTERFACE_SRC) $(CACHE_SRC)

# Object files
OBJECTS = $(ALL_SOURCES:.cpp=.o)

# Targets
TARGET_FULL = test_phi3_minimal_full
SOURCE = test_phi3.cpp

.PHONY: all clean find-sources test-full-minimal

all: find-sources $(TARGET_FULL)

# Find what sources are actually available
find-sources:
	@echo "🔍 Available source files:"
	@find $(SRC_DIR) -name "*.cpp" | wc -l | xargs echo "Total .cpp files found:"
	@echo ""
	@echo "📁 Missing critical files (these might cause linking errors):"
	@[ ! -f "$(SRC_DIR)/models/embeddings.cpp" ] && echo "  - embeddings.cpp (MISSING)" || echo "  - embeddings.cpp (found)"
	@[ ! -f "$(SRC_DIR)/models/multimodal_features.cpp" ] && echo "  - multimodal_features.cpp (MISSING)" || echo "  - multimodal_features.cpp (found)"
	@echo ""

# Compile individual object files
%.o: %.cpp
	@echo "📝 Compiling $<..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Build the test executable
$(TARGET_FULL): $(OBJECTS)
	@echo "🔨 Building $(TARGET_FULL) with all available files..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET_FULL) $(SOURCE) $(OBJECTS) $(LIBS)
	@echo "✅ Build complete!"

# Test the build
test-full-minimal: $(TARGET_FULL)
	@echo "🚀 Testing minimal build..."
	./$(TARGET_FULL)

# Clean
clean:
	rm -f $(TARGET_FULL)
	find $(SRC_DIR) -name "*.o" -delete

# Alternative: Use the working dynamic library approach
build-with-dylib:
	@echo "🔨 Building with pre-built dynamic library (recommended)..."
	$(CXX) -std=c++17 -O2 -Wall -I$(SRC_DIR) -I$(SRC_DIR)/ort \
		-o test_phi3_dylib $(SOURCE) \
		-L$(BUILD_DIR) -lonnxruntime-genai \
		-Wl,-rpath,$(BUILD_DIR)
	@echo "✅ Dynamic library build complete!"