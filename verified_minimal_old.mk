# Verified Minimal Makefile for macOS - Based on Symbol Analysis
# Includes all source files needed based on our undefined symbol investigation

# Paths
GENAI_ROOT = ../onnxruntime-genai
BUILD_DIR = $(GENAI_ROOT)/build/macOS/RelWithDebInfo
SRC_DIR = $(GENAI_ROOT)/src
EXT_SRC_DIR = $(BUILD_DIR)/_deps/onnxruntime_extensions-src

# Compiler settings
CXX = clang++
CC = clang
CXXFLAGS = -std=c++20 -O2 -Wall -fPIC
CFLAGS = -std=c11 -O2 -Wall -fPIC

# Comprehensive include paths based on our analysis
INCLUDES = -I$(SRC_DIR) \
           -I$(SRC_DIR)/ort \
           -I$(BUILD_DIR)/_deps/nlohmann_json-src/include \
           -I$(BUILD_DIR)/_deps/gsl-src/include \
           -I$(BUILD_DIR)/_deps/ortlib-src/build/native/include \
           -I$(EXT_SRC_DIR)/include \
           -I$(EXT_SRC_DIR)/shared/api \
           -I$(EXT_SRC_DIR)/shared/lib \
           -I$(EXT_SRC_DIR)/base \
           -I$(EXT_SRC_DIR)/operators \
           -I$(EXT_SRC_DIR)/operators/tokenizer \
           -I$(EXT_SRC_DIR)/operators/audio \
           -I$(EXT_SRC_DIR)/operators/text \
           -I$(EXT_SRC_DIR) \
           -I$(BUILD_DIR)/_deps/dlib-src \
           -I$(BUILD_DIR)/_deps/dlib-src/dlib/external/libpng \
           -I$(BUILD_DIR)/_deps/dlib-src/dlib/external/libjpeg \
           -I$(BUILD_DIR)/_deps/dr_libs-src

# Library paths - only ONNX Runtime core, not custom operator libraries (we compile those from source)
LIBS = -L$(BUILD_DIR) -lonnxruntime \
       -Wl,-rpath,$(BUILD_DIR) \
       -framework Foundation -framework CoreML -framework CoreFoundation \
       -framework CoreGraphics -framework ImageIO -framework CoreServices

# Core GenAI source files
GENAI_SOURCES = $(SRC_DIR)/ort_genai_c.cpp \
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

# Model source files
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

# Previously missing files that we identified
MISSING_SOURCES = $(SRC_DIR)/models/embeddings.cpp \
                  $(SRC_DIR)/models/multi_modal_features.cpp \
                  $(SRC_DIR)/models/processor.cpp \
                  $(SRC_DIR)/models/windowed_kv_cache.cpp \
                  $(SRC_DIR)/models/threadpool.cpp

# Processor sources (needed for vtables)
PROCESSOR_SOURCES = $(SRC_DIR)/models/whisper_processor.cpp \
                    $(SRC_DIR)/models/phi_image_processor.cpp \
                    $(SRC_DIR)/models/phi_multimodal_processor.cpp \
                    $(SRC_DIR)/models/gemma_image_processor.cpp

# CPU interface
CPU_SOURCES = $(SRC_DIR)/cpu/interface.cpp

# Custom operator sources (removing speech and image processing since we don't need them)
CUSTOM_OP_SOURCES = $(EXT_SRC_DIR)/shared/lib/ops_registry.cc \
                    $(EXT_SRC_DIR)/shared/api/c_api_utils.cc \
                    $(EXT_SRC_DIR)/shared/api/c_api_tokenizer.cc \
                    $(EXT_SRC_DIR)/shared/api/tokenizer_impl.cc \
                    $(EXT_SRC_DIR)/shared/api/chat_template.cc \
                    $(EXT_SRC_DIR)/operators/tokenizer/bpe_kernels.cc \
                    $(EXT_SRC_DIR)/operators/tokenizer/unicode.cc \
                    $(EXT_SRC_DIR)/base/base64.cc \
                    $(EXT_SRC_DIR)/base/string_utils.cc \
                    $(EXT_SRC_DIR)/base/string_tensor.cc

# Device interface stubs
STUB_SOURCES = device_interface_stubs.cpp

# All sources combined
ALL_SOURCES = $(GENAI_SOURCES) \
              $(MODEL_SOURCES) \
              $(MISSING_SOURCES) \
              $(PROCESSOR_SOURCES) \
              $(CPU_SOURCES) \
              $(CUSTOM_OP_SOURCES) \
              $(STUB_SOURCES)

# Object files
OBJECTS = $(ALL_SOURCES:.cpp=.o)
OBJECTS := $(OBJECTS:.cc=.o)
OBJECTS := $(OBJECTS:.c=.o)

# Targets
TARGET = test_phi3_verified
SOURCE = test_phi3.cpp

.PHONY: all clean check-files test verify-symbols

all: check-files $(TARGET)

# Check which source files actually exist
check-files:
	@echo "🔍 Verifying source files..."
	@missing=0; total=0; \
	for src in $(ALL_SOURCES); do \
		total=$$((total + 1)); \
		if [ -f "$$src" ]; then \
			echo "✅ $$src"; \
		else \
			echo "❌ $$src (MISSING)"; \
			missing=$$((missing + 1)); \
		fi; \
	done; \
	echo ""; \
	echo "📊 Summary: $$missing missing files out of $$total total"
	@echo ""
	@echo "📁 Custom operator files check:"
	@ls -la $(EXT_SRC_DIR)/shared/api/ 2>/dev/null | head -5 || echo "Custom ops directory not accessible"
	@echo ""
	@echo "📁 Tokenizer files check:"
	@ls -la $(EXT_SRC_DIR)/operators/tokenizer/ 2>/dev/null || echo "Tokenizer directory not accessible"

# Create minimal device interface stubs 
device_interface_stubs.cpp:
	@echo "📝 Creating minimal stubs file..."
	@echo "#include <string>" > device_interface_stubs.cpp
	@echo "" >> device_interface_stubs.cpp
	@echo "// Minimal stubs for text-only GenAI" >> device_interface_stubs.cpp
	@echo "namespace Generators {" >> device_interface_stubs.cpp
	@echo "    struct DeviceInterface;" >> device_interface_stubs.cpp
	@echo "    class Model;" >> device_interface_stubs.cpp
	@echo "    DeviceInterface* GetQNNInterface() { return nullptr; }" >> device_interface_stubs.cpp
	@echo "    DeviceInterface* GetWebGPUInterface() { return nullptr; }" >> device_interface_stubs.cpp
	@echo "    DeviceInterface* GetOpenVINOInterface() { return nullptr; }" >> device_interface_stubs.cpp
	@echo "    bool IsOpenVINOStatefulModel(const Model& model) { return false; }" >> device_interface_stubs.cpp
	@echo "}" >> device_interface_stubs.cpp
	@echo "" >> device_interface_stubs.cpp
	@echo "// Normalizer stub for text processing" >> device_interface_stubs.cpp
	@echo "namespace ort_extensions {" >> device_interface_stubs.cpp
	@echo "    namespace normalizer {" >> device_interface_stubs.cpp
	@echo "        std::string Search(const std::string& text) { return text; }" >> device_interface_stubs.cpp
	@echo "    }" >> device_interface_stubs.cpp
	@echo "}" >> device_interface_stubs.cpp

# Compile individual object files
%.o: %.cpp
	@echo "📝 Compiling $<..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

%.o: %.cc
	@echo "📝 Compiling $<..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

%.o: %.c
	@echo "📝 Compiling $< (C)..."
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Build the test executable
$(TARGET): device_interface_stubs.cpp $(OBJECTS)
	@echo "🔨 Building $(TARGET) with verified source files..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET) $(SOURCE) $(OBJECTS) $(LIBS)
	@echo "✅ Build complete!"

# Test the build
test: $(TARGET)
	@echo "🚀 Testing verified build..."
	./$(TARGET)

# Verify undefined symbols (for debugging)
verify-symbols: $(TARGET)
	@echo "🔍 Checking for undefined symbols..."
	@nm -u $(TARGET) | head -20 || echo "No undefined symbols or nm failed"

# Clean
clean:
	rm -f $(TARGET) device_interface_stubs.cpp
	find $(SRC_DIR) -name "*.o" -delete 2>/dev/null || true
	find $(EXT_SRC_DIR) -name "*.o" -delete 2>/dev/null || true
	rm -f *.o

# Alternative builds for testing
essential-only:
	@echo "🔨 Building with essential sources only..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o test_essential $(SOURCE) \
		$(GENAI_SOURCES:.cpp=.o) $(MODEL_SOURCES:.cpp=.o) $(CPU_SOURCES:.cpp=.o) \
		device_interface_stubs.cpp $(LIBS)

# Show what we're about to build
show-config:
	@echo "📋 Build Configuration:"
	@echo "GenAI sources: $(words $(GENAI_SOURCES))"
	@echo "Model sources: $(words $(MODEL_SOURCES))"
	@echo "Missing sources: $(words $(MISSING_SOURCES))"
	@echo "Processor sources: $(words $(PROCESSOR_SOURCES))"
	@echo "Custom op sources: $(words $(CUSTOM_OP_SOURCES))"
	@echo "Total sources: $(words $(ALL_SOURCES))"
	@echo ""
	@echo "🎯 This should resolve all undefined symbols we found!"
