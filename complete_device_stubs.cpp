#include <string>
#include <span>
#include <cstdint>

// Forward declarations for ONNX Runtime Extensions types
struct OrtxProcessor;
struct OrtxRawAudios;
struct OrtxRawImages;
struct OrtxFeatureExtractor;

// Use proper C-compatible return type
typedef void* OrtStatus;

// OrtxStatus implementation that's C-compatible
struct OrtxStatus {
    OrtStatus status_;
    
    OrtxStatus() : status_(nullptr) {}
    explicit OrtxStatus(OrtStatus status) : status_(status) {}
    
    operator OrtStatus() const { return status_; }
};

// External "C" functions that are missing from ONNX Runtime Extensions
extern "C" {

// Processor creation
OrtStatus OrtxCreateProcessor(OrtxProcessor** processor, void* ort_env, const char* config_path) {
    // For text-only demo, return null processor
    if (processor) *processor = nullptr;
    return nullptr; // Success (null means no error)
}

// Audio processing stubs
OrtStatus OrtxCreateRawAudios(OrtxRawAudios** audios, 
                              const void* const* audio_data, 
                              const size_t* audio_data_len, 
                              size_t num_audios) {
    if (audios) *audios = nullptr;
    return nullptr; // Success for stub
}

OrtStatus OrtxLoadAudios(OrtxRawAudios** audios, const char* const* audio_paths, size_t num_paths) {
    if (audios) *audios = nullptr;
    return nullptr; // Success for stub
}

OrtStatus OrtxCreateSpeechFeatureExtractor(OrtxFeatureExtractor** extractor, 
                                           void* ort_env, 
                                           const char* config_path) {
    if (extractor) *extractor = nullptr;
    return nullptr; // Success for stub
}

OrtStatus OrtxSpeechLogMel(OrtxFeatureExtractor* extractor,
                           OrtxRawAudios* raw_audios,
                           void** output_tensor) {
    if (output_tensor) *output_tensor = nullptr;
    return nullptr; // Success for stub
}

// Image processing stubs  
OrtStatus OrtxCreateRawImages(OrtxRawImages** images,
                              const void* const* image_data,
                              const size_t* image_data_len,
                              size_t num_images) {
    if (images) *images = nullptr;
    return nullptr; // Success for stub
}

OrtStatus OrtxLoadImages(OrtxRawImages** images, const char* const* image_paths, size_t num_paths) {
    if (images) *images = nullptr;
    return nullptr; // Success for stub
}

OrtStatus OrtxImagePreProcess(OrtxProcessor* processor,
                              OrtxRawImages* images,
                              void** output_tensor) {
    if (output_tensor) *output_tensor = nullptr;
    return nullptr; // Success for stub
}

OrtStatus OrtxFeatureExtraction(OrtxFeatureExtractor* extractor,
                                OrtxRawImages* images,
                                void** output_tensor) {
    if (output_tensor) *output_tensor = nullptr;
    return nullptr; // Success for stub
}

} // extern "C"

// Base64 functions (needed by tokenizer)
void base64_decode(const std::string& input, std::vector<unsigned char>& output) {
    // Simple stub - just clear output for text-only build
    output.clear();
}

// Generators namespace stubs
namespace Generators {
    struct DeviceInterface;
    class Model;
    class State;
    class Images;
    class Audios;
    
    DeviceInterface* GetQNNInterface() { return nullptr; }
    DeviceInterface* GetWebGPUInterface() { return nullptr; }
    DeviceInterface* GetOpenVINOInterface() { return nullptr; }
    bool IsOpenVINOStatefulModel(const Model& model) { return false; }
    
    // Audio/Image loading functions (called by processor.cpp)
    void* LoadAudiosFromBuffers(std::span<const void*> buffers, std::span<const size_t> sizes) {
        return nullptr; // Stub for text-only demo
    }
    
    void* LoadAudios(const std::span<const char* const>& paths) {
        return nullptr; // Stub for text-only demo  
    }
    
    void* LoadImagesFromBuffers(std::span<const void*> buffers, std::span<const size_t> sizes) {
        return nullptr; // Stub for text-only demo
    }
    
    void* LoadImages(std::span<const char* const> paths) {
        return nullptr; // Stub for text-only demo
    }
    
    // Windowed KV Cache stub
    class WindowedKeyValueCache {
    public:
        WindowedKeyValueCache(State& state) {
            // Stub constructor - not used in text-only build
        }
    };
    
    // MultiModal processor stub methods
    class MultiModalProcessor {
    public:
        std::unique_ptr<void> Process(const std::string& prompt, const Images* images, const Audios* audios) const {
            throw std::runtime_error("MultiModalProcessor not supported in text-only build");
        }
    };
}

// ONNX Runtime Extensions tokenizer stubs
namespace ort_extensions {
    namespace normalizer {
        std::string Search(const std::string& text) { 
            return text; // Pass through for text processing
        }
    }
    
    // TokenizerImpl stubs for missing methods
    class TokenizerImpl {
    public:
        void LoadChatTemplate() {
            // Stub - chat templates not supported in text-only build
        }
        
        bool ApplyChatTemplate(const char* tmpl, const char* messages, 
                              const char* tools, std::string& output, 
                              std::vector<uint32_t>& tokens, bool add_generation_prompt, 
                              bool tokenize) const {
            // Simple stub - just return the messages as-is for text-only
            if (messages) {
                output = std::string(messages);
            }
            return true;
        }
    };
}
