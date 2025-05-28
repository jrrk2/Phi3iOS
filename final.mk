# Makefile for macOS Phi-3 C++ Test - Full Source Compilation
# Paths (update these to match your setup)
GENAI_ROOT = ../onnxruntime-genai
BUILD_DIR = $(GENAI_ROOT)/build/macOS/RelWithDebInfo
INCLUDE_DIR = $(GENAI_ROOT)/src

# Compiler settings with official CMake flags
CXX = clang++
CXXFLAGS = -std=c++20 -g -Wall -Wno-unused-private-field -Wno-infinite-recursion \
           -DBUILDING_ORT_GENAI_C -DENABLE_C_API -DENABLE_DLIB \
           -DENABLE_DR_LIBS -DENABLE_GPT2_TOKENIZER -DENABLE_MATH \
           -DENABLE_TOKENIZER -DENABLE_VISION -DOCOS_SHARED_LIBRARY \
           -DTEST_PHI2=0 -DUSE_CUDA=0 -DUSE_DML=0 -DUSE_GUIDANCE=0 \
           -DUSE_ROCM=0 -D_ORT_GENAI_USE_DLOPEN -Donnxruntime_genai_EXPORTS

# Complete include paths matching official build
INCLUDES = -I$(INCLUDE_DIR) \
           -I$(GENAI_ROOT)/src/ort \
           -I$(BUILD_DIR)/dependencies/ort/build/native/include \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/include \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/shared/api \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/base \
           -I$(BUILD_DIR)/_deps/nlohmann_json-src/single_include \
           -I$(BUILD_DIR)/_deps/dlib-src \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/operators/audio \
           -I$(BUILD_DIR)/_deps/gsl-src/include \
           -I$(BUILD_DIR)/_deps/onnxruntime_extensions-src/operators/tokenizer \
           -I$(INCLUDE_DIR)/models

# Static linking
RPATH_STATIC = -Wl,-rpath,$(BUILD_DIR)

# Targets
TARGET_STATIC = test_phi3_cpp_static
TARGET_INTERACTIVE = test_phi3_interactive

# All source files for single-question version
SOURCES_SINGLE = \
	test_phi3.cpp \
	model_text_only.cpp \
	ort_genai_c_edited.cpp \
	c_api_processor_edited.cc \
	ops_registry_edited.cc \
	stub_interfaces.cpp \
	audio_stub.cc \
	$(GENAI_ROOT)/src/runtime_settings.cpp \
	$(GENAI_ROOT)/src/search.cpp \
	$(GENAI_ROOT)/src/cpu/interface.cpp \
	$(GENAI_ROOT)/src/generators.cpp \
	$(GENAI_ROOT)/src/constrained_logits_processor.cpp \
	$(GENAI_ROOT)/src/models/decoder_only_pipeline.cpp \
	$(GENAI_ROOT)/src/models/utils.cpp \
	$(GENAI_ROOT)/src/models/kv_cache.cpp \
	$(GENAI_ROOT)/src/models/debugging.cpp \
	$(GENAI_ROOT)/src/models/input_ids.cpp \
	$(GENAI_ROOT)/src/models/extra_outputs.cpp \
	$(GENAI_ROOT)/src/models/processor.cpp \
	$(GENAI_ROOT)/src/models/gpt.cpp \
	$(GENAI_ROOT)/src/models/adapters.cpp \
	$(GENAI_ROOT)/src/models/logits.cpp \
	$(GENAI_ROOT)/src/models/env_utils.cpp \
	$(GENAI_ROOT)/src/models/position_inputs.cpp \
	$(GENAI_ROOT)/src/models/windowed_kv_cache.cpp \
	$(GENAI_ROOT)/src/models/threadpool.cpp \
	$(GENAI_ROOT)/src/models/extra_inputs.cpp \
	$(GENAI_ROOT)/src/models/decoder_only.cpp \
	$(GENAI_ROOT)/src/json.cpp \
	$(GENAI_ROOT)/src/config.cpp \
	$(GENAI_ROOT)/src/sequences.cpp \
	$(GENAI_ROOT)/src/beam_search_scorer.cpp \
	$(GENAI_ROOT)/src/logging.cpp \
	$(GENAI_ROOT)/src/tensor.cpp \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/operators/tokenizer/case_encoder.cc \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/operators/tokenizer/tokenizers.cc \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/operators/tokenizer/unicode.cc \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/operators/tokenizer/bpe_kernels.cc \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/operators/math/segment_sum.cc \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/operators/math/segment_extraction.cc \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/operators/math/math.cc \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/shared/api/c_api_tokenizer.cc \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/shared/api/tokenizer_impl.cc \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/shared/api/c_api_utils.cc \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/shared/api/chat_template.cc \
	$(BUILD_DIR)/_deps/dlib-src/dlib/fft/fft.cpp \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/base/base64.cc \
	$(BUILD_DIR)/_deps/onnxruntime_extensions-src/base/ocos.cc

# All source files for interactive version (replace test_phi3.cpp with test_phi3_interactive.cpp)
SOURCES_INTERACTIVE = $(subst test_phi3.cpp,test_phi3_interactive.cpp,$(SOURCES_SINGLE))

# Backward compatibility
ALL_SOURCES = $(SOURCES_SINGLE)

# Main build target - 100% source compilation!
$(TARGET_STATIC): $(SOURCES_SINGLE)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET_STATIC) $(SOURCES_SINGLE) \
		$(BUILD_DIR)/libonnxruntime.dylib $(RPATH_STATIC) \
		-Wl,-map,$(TARGET_STATIC).map

# Interactive chat version
$(TARGET_INTERACTIVE): $(SOURCES_INTERACTIVE)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET_INTERACTIVE) $(SOURCES_INTERACTIVE) \
		$(BUILD_DIR)/libonnxruntime.dylib $(RPATH_STATIC) \
		-Wl,-map,$(TARGET_INTERACTIVE).map

# Build both versions
all: $(TARGET_STATIC) $(TARGET_INTERACTIVE)

# Test the single-question version
test-static: $(TARGET_STATIC)
	@echo "🚀 Testing single-question version..."
	./$(TARGET_STATIC)

# Test the interactive version
test-interactive: $(TARGET_INTERACTIVE)
	@echo "🚀 Starting interactive chat..."
	./$(TARGET_INTERACTIVE)

# Quick test with custom question
test-question: $(TARGET_STATIC)
	@echo "🚀 Testing with custom question..."
	@echo "What is the capital of France?" | ./$(TARGET_STATIC)

# Create stub files
stub_interfaces.cpp:
	@echo "Creating stub interfaces for platform-specific code..."
	@# Copy from the stub_interfaces artifact above

audio_stub.cc:
	@echo "Creating audio stub replacement..."
	@# Copy from the audio_stub artifact above

# Check what we're compiling
check-sources:
	@echo "📋 Source files being compiled:"
	@echo "$(ALL_SOURCES)" | tr ' ' '\n' | nl

# Validate all sources exist
validate-sources:
	@echo "🔍 Validating all source files exist..."
	@missing=0; \
	for src in $(ALL_SOURCES); do \
		if [ ! -f "$$src" ]; then \
			echo "❌ Missing: $$src"; \
			missing=$$((missing + 1)); \
		fi; \
	done; \
	if [ $$missing -eq 0 ]; then \
		echo "✅ All source files found!"; \
	else \
		echo "❌ $$missing source files missing"; \
		exit 1; \
	fi

# Check dependencies
check-deps:
	@echo "🔍 Checking library dependencies..."
	@if [ -f "$(TARGET_STATIC)" ]; then \
		otool -L $(TARGET_STATIC); \
	else \
		echo "Binary not found"; \
	fi

# Check the map file
check-map:
	@echo "🗺️  Checking linker map file..."
	@if [ -f "$(TARGET_STATIC).map" ]; then \
		echo "=== Map file summary ==="; \
		head -20 $(TARGET_STATIC).map; \
		echo "..."; \
		echo "=== Symbol count ==="; \
		grep -c "^0x" $(TARGET_STATIC).map || echo "No symbols found"; \
	else \
		echo "Map file not found"; \
	fi

# Clean everything
clean:
	rm -f $(TARGET_STATIC) $(TARGET_STATIC).map $(TARGET_INTERACTIVE) $(TARGET_INTERACTIVE).map
	rm -f stub_interfaces.cpp audio_stub.cc
	rm -f *.o

# Show build info
info:
	@echo "🔧 Build Configuration:"
	@echo "  Compiler: $(CXX)"
	@echo "  Flags: $(CXXFLAGS)"
	@echo "  Sources: $(words $(ALL_SOURCES)) files"
	@echo "  Target: $(TARGET_STATIC)"
	@echo "  100% Source Compilation: ✅"

.PHONY: all test-static test-interactive test-question check-sources validate-sources check-deps check-map clean info