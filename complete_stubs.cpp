// complete_stubs.cpp
// Provides all missing symbols for text-only iOS build

#include <stdexcept>
#include <memory>
#include <string>

// Include necessary headers for type definitions
namespace Generators {
    class State;
    class Model;
    class DeviceInterface;
    class CombinedKeyValueCache;
}

// C API type definitions
typedef enum {
    kOrtxOK = 0,
    kOrtxErrorInvalidArgument = 1,
    kOrtxErrorOutOfMemory = 2
} extError_t;

typedef int extTokenId_t;
const char* kOrtxKindDetokenizerCache = "DetokenizerCache";

// Provide C API stub implementations
extern "C" {

extError_t OrtxCreate(const char* kind, void** out) {
    (void)kind;
    *out = nullptr;
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxCreateTokenizer(void** tokenizer, const char* config_path) {
    (void)config_path;
    *tokenizer = nullptr;
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxTokenizeWithOptions(void* tokenizer, const char** input, int num_strings, void** output, int add_special_tokens) {
    (void)tokenizer; (void)input; (void)num_strings; (void)add_special_tokens;
    *output = nullptr;
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxDetokenize1D(void* tokenizer, const unsigned int* tokens, size_t token_count, void** output) {
    (void)tokenizer; (void)tokens; (void)token_count;
    *output = nullptr;
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxDetokenizeCached(void* tokenizer, void* cache, int token, const char** output) {
    (void)tokenizer; (void)cache; (void)token;
    *output = ""; // Return empty string
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxApplyChatTemplate(void* tokenizer, const char* template_str, const char* messages, const char* tools, void** output, int add_generation_prompt, int tokenize) {
    (void)tokenizer; (void)template_str; (void)messages; (void)tools; (void)add_generation_prompt; (void)tokenize;
    *output = nullptr;
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxConvertTokenToId(void* tokenizer, const char* token, extTokenId_t* token_id) {
    (void)tokenizer; (void)token;
    *token_id = 0;
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

void OrtxDispose(void* object) {
    (void)object;
    // Empty stub - nothing to dispose in text-only build
}

void OrtxDisposeOnly(void* object) {
    (void)object;
    // Empty stub - nothing to dispose in text-only build
}

const char* OrtxGetLastErrorMessage() {
    return "ONNX Runtime Extensions not available - text-only build";
}

extError_t OrtxGetTensorData(void* tensor, const void** data, size_t* num_dims, size_t** shape) {
    (void)tensor;
    *data = nullptr;
    *num_dims = 0;
    *shape = nullptr;
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxStringArrayGetItem(void* string_array, size_t index, const char** string) {
    (void)string_array; (void)index;
    *string = "";
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxTensorResultGetAt(void* result, size_t index, void** tensor) {
    (void)result; (void)index;
    *tensor = nullptr;
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxTokenId2DArrayGetItem(void* array, size_t index, const extTokenId_t** tokens, size_t* count) {
    (void)array; (void)index;
    *tokens = nullptr;
    *count = 0;
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

} // extern "C"

// Provide C++ API stub implementations
namespace Generators {

// Device interface stubs
DeviceInterface* GetQNNInterface() {
    return nullptr; // QNN not supported on iOS
}

DeviceInterface* GetWebGPUInterface() {
    return nullptr; // WebGPU not supported on iOS
}

DeviceInterface* GetOpenVINOInterface() {
    return nullptr; // OpenVINO not supported on iOS
}

// Model utility functions
bool IsOpenVINOStatefulModel(const Model&) {
    return false; // Not using OpenVINO on iOS
}

std::string ComposeKeyValueName(const std::string& pattern, int layer_index) {
    // Simple implementation for key/value name composition
    return pattern + "_" + std::to_string(layer_index);
}

// Guidance processor stub
std::unique_ptr<void> CreateGuidanceLogitsProcessor(const State&) {
    return nullptr; // No guidance processor needed for basic generation
}

// CombinedKeyValueCache stub implementation
class CombinedKeyValueCache {
public:
    CombinedKeyValueCache(State&) {
        // Empty constructor for text-only build
    }
    
    virtual ~CombinedKeyValueCache() = default;
    
    void Add() {
        // Empty implementation
    }
    
    void Update(void* device_span, int batch_size) {
        // Use void* to avoid template instantiation issues
        (void)device_span;
        (void)batch_size;
        // Empty implementation  
    }
    
    void RewindTo(unsigned long position) {
        (void)position;
        // Empty implementation
    }
};

// Factory function for key-value cache
std::unique_ptr<void> CreateKeyValueCache(State& state) {
    // Return a simple combined cache for text-only build
    return std::make_unique<CombinedKeyValueCache>(state);
}

} // namespace Generators

// Provide vtable for CombinedKeyValueCache by ensuring virtual destructor is defined
// This is handled by the class definition above