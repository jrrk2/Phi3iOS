# Makefile for macOS Phi-3 C++ Test
# Paths (update these to match your setup)
# Object files list (definitive list from working build)
OBJECT_FILES = \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/runtime_settings.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/search.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/cpu/interface.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/webgpu/interface.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/openvino/interface.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/qnn/interface.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/generators.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/constrained_logits_processor.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/decoder_only_pipeline.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/utils.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/kv_cache.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/debugging.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/input_ids.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/extra_outputs.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/processor.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/gpt.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/adapters.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/logits.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/env_utils.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/position_inputs.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/windowed_kv_cache.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/threadpool.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/extra_inputs.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/models/decoder_only.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/json.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/config.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/sequences.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/beam_search_scorer.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/logging.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/tensor.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ocos_operators.dir/operators/tokenizer/case_encoder.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ocos_operators.dir/operators/tokenizer/tokenizers.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ocos_operators.dir/operators/tokenizer/unicode.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ocos_operators.dir/operators/tokenizer/bpe_kernels.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ocos_operators.dir/operators/math/segment_sum.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ocos_operators.dir/operators/math/segment_extraction.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ocos_operators.dir/operators/math/math.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ortcustomops.dir/shared/lib/ops_registry.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ortcustomops.dir/shared/api/c_api_tokenizer.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ortcustomops.dir/shared/api/c_api_feature_extraction.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ortcustomops.dir/shared/api/tokenizer_impl.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ortcustomops.dir/shared/api/c_api_utils.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ortcustomops.dir/shared/api/speech_extractor.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ortcustomops.dir/shared/api/chat_template.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/noexcep_operators.dir/__/dlib-src/dlib/fft/fft.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/noexcep_operators.dir/operators/audio/audio.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/noexcep_operators.dir/operators/audio/audio_decoder.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/noexcep_operators.dir/base/base64.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/noexcep_operators.dir/base/ocos.cc.o

# Compiler settings
CXX = clang++
CXXFLAGS = -std=c++20 -O2 -Wall -Wno-unused-private-field
INCLUDES = -I$(INCLUDE_DIR) \
           -I$(GENAI_ROOT)/src/ort \
           -I../onnxruntime-genai/build/macOS/RelWithDebInfo/dependencies/ort/build/native/include \
           -I../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/include \
           -I../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/shared/api \
           -I../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/base \
           -I../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/nlohmann_json-src/single_include

# Static linking (explicit library files)
LIBS_STATIC = other.a $(BUILD_DIR)/libonnxruntime.dylib
RPATH_STATIC = -Wl,-rpath,$(BUILD_DIR)

# Targets
TARGET_STATIC = test_phi3_cpp_static
SOURCE = test_phi3.cpp \
         ../onnxruntime-genai/src/models/model_text_only.cpp \
         dummy_implementations.cpp \
         ../onnxruntime-genai/src/ort_genai_c_edited.cpp \
         ../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/shared/api/c_api_processor_edited.cc

test-static: $(TARGET_STATIC)
	@echo "🚀 Testing static version..."
	./$(TARGET_STATIC)

other.a:

# Paths (update these to match your setup)
GENAI_ROOT = ../onnxruntime-genai
BUILD_DIR = $(GENAI_ROOT)/build/macOS/RelWithDebInfo
INCLUDE_DIR = $(GENAI_ROOT)/src
ORT_GENAI_STATIC_LIB = $(BUILD_DIR)/libonnxruntime-genai_static.a

other.a: dummy_image_processors.o
	# Create archive with definitive list of object files (excluding ones now compiled directly)
	ar rc $@ dummy_image_processors.o $(OBJECT_FILES)

dummy_image_processors.o: dummy_implementations.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c dummy_implementations.cpp -o dummy_image_processors.o

# Build static version (explicit libs)
$(TARGET_STATIC): $(SOURCE) other.a
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET_STATIC) $(SOURCE) $(LIBS_STATIC) $(RPATH_STATIC) -Wl,-map,$(TARGET_STATIC).map

# Check dependencies
check-deps:
	@echo "🔍 Checking static library dependencies..."
	@if [ -f "$(TARGET_STATIC)" ]; then \
		otool -L $(TARGET_STATIC); \
	else \
		echo "Static binary not found"; \
	fi

# Find undefined symbols
check-symbols:
	@echo "🔍 Checking for undefined symbols in other.a..."
	@nm -u other.a 2>/dev/null || echo "No undefined symbols found"

# Find all available libraries
find-libs:
	@echo "🔍 Looking for ONNX Runtime GenAI libraries..."
	@find $(GENAI_ROOT) -name "*.dylib" -o -name "*.a" | head -10

# Find headers  
find-headers:
	@echo "🔍 Looking for ONNX Runtime GenAI headers..."
	@find $(GENAI_ROOT) -name "*.h" | grep -i genai | head -10

# Clean
clean:
	rm -f $(TARGET_STATIC) $(TARGET_STATIC).map $(TARGET_STATIC)_from_source other.a other_from_source.a dummy_image_processors.o dummy_implementations.o
	rm -rf build_temp
	rm -f test_*.o

# Check map file
check-map:
	@echo "🗺️  Checking linker map file..."
	@if [ -f "$(TARGET_STATIC).map" ]; then \
		echo "=== Map file summary ==="; \
		head -20 $(TARGET_STATIC).map; \
		echo "..."; \
		echo "=== Symbol count ==="; \
		grep -c "^0x" $(TARGET_STATIC).map || echo "No symbols found"; \
	else \
		echo "Map file not found. Build first with: make -f static.mk"; \
	fi

# Test compiling individual source files
test-compile-sources:
	@echo "🧪 Testing compilation of individual source files..."
	@failed=0; total=0; \
	for obj in $(OBJECT_FILES); do \
		src=$(echo $obj | sed 's/\.o$//' | sed 's/CMakeFiles\/[^\/]*\.dir\///'); \
		if [ -f "$src" ]; then \
			total=$((total + 1)); \
			echo "Testing: $src"; \
			if $(CXX) $(CXXFLAGS) $(INCLUDES) -c "$src" -o "test_$(basename $src).o" 2>/dev/null; then \
				echo "✅ $src"; \
				rm -f "test_$(basename $src).o"; \
			else \
				echo "❌ $src"; \
				failed=$((failed + 1)); \
			fi; \
		else \
			echo "⚠️  Source not found: $src"; \
		fi; \
	done; \
	echo ""; \
	echo "📊 Results: $((total - failed))/$total files compiled successfully"

# List source files that correspond to object files
list-source-files:
	@echo "📋 Listing source files from object list..."
	@for obj in $(OBJECT_FILES); do \
		src=$(echo $$obj | sed 's/\.o$//' | sed 's/CMakeFiles\/[^\/]*\.dir\///'); echo $$src; \
		if [ -f "$$src" ]; then \
			echo "✅ $$src"; \
		else \
			echo "❌ $$src (not found)"; \
		fi; \
	done

# Create a new target that compiles more from source
compile-from-source: dummy_image_processors.o
	@echo "🔨 Building with maximum source compilation..."
	@mkdir -p build_temp
	@compiled_objs=""; \
	failed_objs=""; \
	for obj in $(OBJECT_FILES); do \
		src=$(echo $obj | sed 's/\.o$//' | sed 's/CMakeFiles\/[^\/]*\.dir\///'); \
		if [ -f "$src" ]; then \
			basename_obj="build_temp/$(basename $src).o"; \
			if $(CXX) $(CXXFLAGS) $(INCLUDES) -c "$src" -o "$basename_obj" 2>/dev/null; then \
				compiled_objs="$compiled_objs $basename_obj"; \
			else \
				failed_objs="$failed_objs $obj"; \
			fi; \
		else \
			failed_objs="$failed_objs $obj"; \
		fi; \
	done; \
	echo "Creating archive with compiled objects..."; \
	ar rc other_from_source.a dummy_image_processors.o $compiled_objs $failed_objs; \
	echo "Linking final executable..."; \
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET_STATIC)_from_source $(SOURCE) other_from_source.a $(BUILD_DIR)/libonnxruntime.dylib $(RPATH_STATIC)

.PHONY: all test-static test-compile-sources list-source-files compile-from-source check-deps check-symbols check-map find-libs find-headers clean
