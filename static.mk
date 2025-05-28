# Makefile for macOS Phi-3 C++ Test
# filtered_source_list.mk
# Include this file in your main Makefile

# Files that compile successfully from source
SUCCESSFUL_SOURCES = \
	test_phi3.cpp \
	model_text_only.cpp \
	dummy_implementations.cpp \
	ort_genai_c_edited.cpp \
	c_api_processor_edited.cc \

SPARE_SOURCES = \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/operators/tokenizer/bpe_kernels.cc \

LIB_SOURCES = \
	../onnxruntime-genai/src/runtime_settings.cpp \
	../onnxruntime-genai/src/search.cpp \
	../onnxruntime-genai/src/cpu/interface.cpp \
	../onnxruntime-genai/src/generators.cpp \
	../onnxruntime-genai/src/constrained_logits_processor.cpp \
	../onnxruntime-genai/src/models/decoder_only_pipeline.cpp \
	../onnxruntime-genai/src/models/utils.cpp \
	../onnxruntime-genai/src/models/kv_cache.cpp \
	../onnxruntime-genai/src/models/debugging.cpp \
	../onnxruntime-genai/src/models/input_ids.cpp \
	../onnxruntime-genai/src/models/extra_outputs.cpp \
	../onnxruntime-genai/src/models/processor.cpp \
	../onnxruntime-genai/src/models/gpt.cpp \
	../onnxruntime-genai/src/models/adapters.cpp \
	../onnxruntime-genai/src/models/logits.cpp \
	../onnxruntime-genai/src/models/env_utils.cpp \
	../onnxruntime-genai/src/models/position_inputs.cpp \
	../onnxruntime-genai/src/models/windowed_kv_cache.cpp \
	../onnxruntime-genai/src/models/threadpool.cpp \
	../onnxruntime-genai/src/models/extra_inputs.cpp \
	../onnxruntime-genai/src/models/decoder_only.cpp \
	../onnxruntime-genai/src/json.cpp \
	../onnxruntime-genai/src/config.cpp \
	../onnxruntime-genai/src/sequences.cpp \
	../onnxruntime-genai/src/beam_search_scorer.cpp \
	../onnxruntime-genai/src/logging.cpp \
	../onnxruntime-genai/src/tensor.cpp \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/operators/tokenizer/case_encoder.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/operators/tokenizer/tokenizers.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/operators/tokenizer/unicode.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/operators/math/segment_sum.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/operators/math/segment_extraction.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/operators/math/math.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/shared/lib/ops_registry.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/shared/api/c_api_tokenizer.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/shared/api/tokenizer_impl.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/shared/api/c_api_utils.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/shared/api/chat_template.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/dlib-src/dlib/fft/fft.cpp \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/operators/audio/audio.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/base/base64.cc \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/base/ocos.cc

# Pre-built object files for sources that failed to compile
FAILED_OBJECTS = \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/webgpu/interface.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/openvino/interface.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/qnn/interface.cpp.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/ortcustomops.dir/shared/api/speech_extractor.cc.o \
	../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/noexcep_operators.dir/operators/audio/audio_decoder.cc.o

# Paths (update these to match your setup)
GENAI_ROOT = ../onnxruntime-genai
BUILD_DIR = $(GENAI_ROOT)/build/macOS/RelWithDebInfo
INCLUDE_DIR = $(GENAI_ROOT)/src
ORT_GENAI_STATIC_LIB = $(BUILD_DIR)/libonnxruntime-genai_static.a

# Compiler settings
CXX = clang++
CXXFLAGS = -std=c++20 -g -Wall
INCLUDES = -I$(INCLUDE_DIR) -I$(GENAI_ROOT)/src/ort \
-I../onnxruntime-genai/build/macOS/RelWithDebInfo/dependencies/ort/build/native/include \
-I../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/include \
-I../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/shared/api \
-I../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/base \
-I../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/nlohmann_json-src/single_include \
-I../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/dlib-src \
-I../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/operators/audio \
-I../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/gsl-src/include \
-I../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-src/operators/tokenizer \
-I../onnxruntime-genai/src/models \

# Static linking (explicit library files)
LIBS_STATIC = other.a $(BUILD_DIR)/libonnxruntime.dylib
RPATH_STATIC = -Wl,-rpath,$(BUILD_DIR)

# Targets
TARGET_STATIC = test_phi3_cpp_static
SOURCE = $(SUCCESSFUL_SOURCES) $(FAILED_OBJECTS)

test-static: $(TARGET_STATIC)
	@echo "🚀 Testing static version..."
	./$(TARGET_STATIC)

other.a:
	ar rc $@ \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/runtime_settings.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/search.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/cpu/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/webgpu/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/openvino/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/qnn/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/cpu/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/webgpu/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/openvino/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/qnn/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/generators.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/constrained_logits_processor.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/cpu/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/webgpu/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/openvino/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/qnn/interface.cpp.o \
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
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/cpu/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/webgpu/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/openvino/interface.cpp.o \
../onnxruntime-genai/build/macOS/RelWithDebInfo/CMakeFiles/onnxruntime-genai.dir/src/qnn/interface.cpp.o \
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
../onnxruntime-genai/build/macOS/RelWithDebInfo/_deps/onnxruntime_extensions-build/CMakeFiles/noexcep_operators.dir/base/ocos.cc.o \

# Build static version (explicit libs)
$(TARGET_STATIC): $(SOURCE) other.a
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(TARGET_STATIC) $(SOURCE) $(LIB_SOURCES) $(LIBS_STATIC) $(RPATH_STATIC) -Wl,-map,filename

# Check dependencies
check-deps:
	@echo "🔍 Checking static library dependencies..."
	@if [ -f "$(TARGET_STATIC)" ]; then \
		otool -L $(TARGET_STATIC); \
	else \
		echo "Static binary not found"; \
	fi

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
	rm -f $(TARGET_STATIC) other.a

.PHONY: all test-static check-deps find-libs find-headers clean
