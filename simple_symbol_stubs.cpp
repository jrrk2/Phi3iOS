// simple_symbol_stubs.cpp
// Provide missing symbols using extern "C" approach to avoid C++ mangling issues

#include <stdexcept>
#include <memory>
#include <string>

// C API stubs
extern "C" {

typedef enum {
    kOrtxOK = 0,
    kOrtxErrorInvalidArgument = 1
} extError_t;

typedef int extTokenId_t;
const char* kOrtxKindDetokenizerCache = "DetokenizerCache";

// All the C API functions
extError_t OrtxCreate(const char* kind, void** out) {
    *out = nullptr;
    return kOrtxErrorInvalidArgument;
}

extError_t OrtxCreateTokenizer(void** tokenizer, const char* config_path) {
    *tokenizer = nullptr;
    return kOrtxErrorInvalidArgument;
}

extError_t OrtxTokenizeWithOptions(void* tokenizer, const char** input, int num_strings, void** output, int add_special_tokens) {
    *output = nullptr;
    return kOrtxErrorInvalidArgument;
}

extError_t OrtxDetokenize1D(void* tokenizer, const unsigned int* tokens, size_t token_count, void** output) {
    *output = nullptr;
    return kOrtxErrorInvalidArgument;
}

extError_t OrtxDetokenizeCached(void* tokenizer, void* cache, int token, const char** output) {
    static const char* empty = "";
    *output = empty;
    return kOrtxErrorInvalidArgument;
}

extError_t OrtxApplyChatTemplate(void* tokenizer, const char* template_str, const char* messages, const char* tools, void** output, int add_generation_prompt, int tokenize) {
    *output = nullptr;
    return kOrtxErrorInvalidArgument;
}

extError_t OrtxConvertTokenToId(void* tokenizer, const char* token, extTokenId_t* token_id) {
    *token_id = 0;
    return kOrtxErrorInvalidArgument;
}

void OrtxDispose(void* object) {
    // Empty
}

void OrtxDisposeOnly(void* object) {
    // Empty
}

const char* OrtxGetLastErrorMessage() {
    return "Extensions not available in text-only build";
}

extError_t OrtxGetTensorData(void* tensor, const void** data, size_t* num_dims, size_t** shape) {
    *data = nullptr;
    *num_dims = 0;
    *shape = nullptr;
    return kOrtxErrorInvalidArgument;
}

extError_t OrtxStringArrayGetItem(void* string_array, size_t index, const char** string) {
    static const char* empty = "";
    *string = empty;
    return kOrtxErrorInvalidArgument;
}

extError_t OrtxTensorResultGetAt(void* result, size_t index, void** tensor) {
    *tensor = nullptr;
    return kOrtxErrorInvalidArgument;
}

extError_t OrtxTokenId2DArrayGetItem(void* array, size_t index, const extTokenId_t** tokens, size_t* count) {
    *tokens = nullptr;
    *count = 0;
    return kOrtxErrorInvalidArgument;
}

} // extern "C"

// Simple namespace functions
namespace Generators {
    class State;
    class Model;
    
    // Simple C-style functions
    void* GetQNNInterface() { return nullptr; }
    void* GetWebGPUInterface() { return nullptr; }
    void* GetOpenVINOInterface() { return nullptr; }
    
    bool IsOpenVINOStatefulModel(const Model&) { return false; }
    
    std::string ComposeKeyValueName(const std::string& pattern, int layer_index) {
        return pattern + "_" + std::to_string(layer_index);
    }
    
    void* CreateGuidanceLogitsProcessor(const State&) { return nullptr; }
    
    void* CreateKeyValueCache(State&) { return nullptr; }
}

// For the CombinedKeyValueCache, let's try a different approach
// Create empty functions with C linkage using mangled names
extern "C" {
    // These are the mangled symbol names - you can get them with: nm your_object_file.o
    // For now, let's create simple stubs that return immediately
    
    void _ZN10Generators20CombinedKeyValueCacheC1ERNS_5StateE() {
        // CombinedKeyValueCache::CombinedKeyValueCache(State&)
        // Empty constructor stub
    }
    
    void _ZN10Generators20CombinedKeyValueCache3AddEv() {
        // CombinedKeyValueCache::Add()
        // Empty method stub
    }
    
    void _ZN10Generators20CombinedKeyValueCache8RewindToEm() {
        // CombinedKeyValueCache::RewindTo(unsigned long)
        // Empty method stub
    }
    
    void _ZN10Generators20CombinedKeyValueCache6UpdateENS_10DeviceSpanIiEEi() {
        // CombinedKeyValueCache::Update(DeviceSpan<int>, int)
        // Empty method stub
    }
}

// Vtable stub - this might be needed
extern "C" {
    // Provide an empty vtable if needed
    void* _ZTVN10Generators20CombinedKeyValueCacheE[4] = {0, 0, 0, 0};
}