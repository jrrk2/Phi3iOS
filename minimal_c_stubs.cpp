// minimal_c_stubs.cpp
// Only provide C API functions - avoid C++ class complications

#include <string>

// C API stubs only
extern "C" {

typedef enum {
    kOrtxOK = 0,
    kOrtxErrorInvalidArgument = 1
} extError_t;

typedef int extTokenId_t;
const char* kOrtxKindDetokenizerCache = "DetokenizerCache";

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
    if (num_dims) *num_dims = 0;
    if (shape) *shape = nullptr;
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

// Only the simple namespace functions that don't involve complex classes
namespace Generators {
    class State;
    class Model;
    
    void* GetQNNInterface() { return nullptr; }
    void* GetWebGPUInterface() { return nullptr; }
    void* GetOpenVINOInterface() { return nullptr; }
    
    bool IsOpenVINOStatefulModel(const Model&) { return false; }
    
    std::string ComposeKeyValueName(const std::string& pattern, int layer_index) {
        return pattern + "_" + std::to_string(layer_index);
    }
    
    void* CreateGuidanceLogitsProcessor(const State&) { return nullptr; }
    
    // Don't provide CreateKeyValueCache or CombinedKeyValueCache - remove files that use them instead
}