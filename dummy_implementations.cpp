// simple_dummy_processors.cpp
// Simple dummy implementations without inheritance to avoid incomplete type issues

#include <memory>
#include <string_view>
#include <vector>

// Forward declarations for needed types
namespace Generators {
    enum class DeviceType;
    class DeviceInterface;
    class Model;
}

namespace ort_extensions {
    template<typename T> class span;
    class TensorResult;
}

namespace Ort { namespace Custom {
    template<typename T> class Tensor;
}}

// Create dummy classes that match the expected symbols without inheritance
namespace Generators {
    class Config {};
    class SessionInfo {};
    
    // Device interface types
    class DeviceInterface {
    public:
        virtual ~DeviceInterface() = default;
    };
    
    // Define PhiImageProcessor as a standalone class
    class PhiImageProcessor {
    public:
        // Constructor that matches the expected signature
        PhiImageProcessor(Config& config, const SessionInfo& session_info) {
            // Dummy implementation
            (void)config;
            (void)session_info;
        }
        
        virtual ~PhiImageProcessor() = default;
    };
    
    // Define GemmaImageProcessor as a standalone class  
    class GemmaImageProcessor {
    public:
        // Constructor that matches the expected signature
        GemmaImageProcessor(Config& config, const SessionInfo& session_info) {
            // Dummy implementation
            (void)config;
            (void)session_info;
        }
        
        virtual ~GemmaImageProcessor() = default;
    };
    
    // Dummy device interface functions
    const DeviceInterface* GetQNNInterface2() {
        static DeviceInterface dummy_interface;
        return &dummy_interface;
    }
    
    const DeviceInterface* GetWebGPUInterface2() {
        static DeviceInterface dummy_interface;
        return &dummy_interface;
    }
    
    const DeviceInterface* GetOpenVINOInterface2() {
        static DeviceInterface dummy_interface;
        return &dummy_interface;
    }
    
    bool IsOpenVINOStatefulModel2(const Model& model) {
        (void)model;
        return false;  // Always return false for dummy implementation
    }
}

namespace ort_extensions {
    template<typename T>
    class span {
    public:
        span() = default;
        // Minimal interface
        size_t size() const { return 0; }
        T* data() const { return nullptr; }
    };
    
    class TensorResult {
    public:
        TensorResult() = default;
        virtual ~TensorResult() = default;
    };
    
    class ImageProcessor {
    public:
        ImageProcessor() = default;
        virtual ~ImageProcessor() = default;
        
        bool Init(std::string_view config) {
            (void)config;
            return true;
        }
        
        bool PreProcess(span<std::vector<unsigned char>> images, TensorResult& result) const {
            (void)images;
            (void)result;
            return true;
        }
    };
    
    // Speech feature extractor dummy implementation
    class SpeechFeatureExtractor {
    public:
        SpeechFeatureExtractor() = default;
        virtual ~SpeechFeatureExtractor() = default;
        
        bool Init(std::string_view config) {
            (void)config;
            return true;
        }
        
        bool Preprocess(span<std::vector<std::byte>> audio_data, TensorResult& result) const {
            (void)audio_data;
            (void)result;
            return true;
        }
        
        bool DoCall(span<std::vector<std::byte>> audio_data, 
                   std::unique_ptr<Ort::Custom::Tensor<float>>& output) const {
            (void)audio_data;
            (void)output;
            return true;
        }
    };
}

// C API implementations
extern "C" {
    int OrtxCreateProcessor2(void** processor) {
        if (!processor) return -1;
        
        try {
            *processor = new ort_extensions::ImageProcessor();
            return 0;
        } catch (...) {
            return -1;
        }
    }
    
    int OrtxImagePreProcess2(void* processor, void* images, void* result) {
        if (!processor) return -1;
        (void)images;
        (void)result;
        return 0;
    }
    
    // Speech feature extractor C API
    int OrtxCreateSpeechFeatureExtractor2(void** extractor) {
        if (!extractor) return -1;
        
        try {
            *extractor = new ort_extensions::SpeechFeatureExtractor();
            return 0;
        } catch (...) {
            return -1;
        }
    }
    
    int OrtxFeatureExtraction(void* extractor, void* audio_data, void* result) {
        if (!extractor) return -1;
        (void)audio_data;
        (void)result;
        return 0;
    }
    
    int OrtxSpeechLogMel(void* extractor, void* audio_data, void* output) {
        if (!extractor) return -1;
        (void)audio_data;
        (void)output;
        return 0;
    }
    
    // Audio loading C API functions
    int OrtxCreateRawAudios(void** raw_audios) {
        if (!raw_audios) return -1;
        
        // Create a dummy audio container
        *raw_audios = malloc(1); // Minimal allocation
        return 0;
    }
    
    int OrtxLoadAudios(const char* const* audio_paths, size_t num_audios, void** raw_audios) {
        if (!audio_paths || !raw_audios) return -1;
        
        // Dummy implementation - just create empty audio container
        (void)num_audios; // Suppress unused parameter warning
        *raw_audios = malloc(1); // Minimal allocation
        return 0;
    }
    
    // Optional: cleanup function for raw audios
    void OrtxDisposeRawAudios(void* raw_audios) {
        if (raw_audios) {
            free(raw_audios);
        }
    }
}

// If you need to satisfy vtable requirements, you might need these:
// These are weak symbols that can be overridden if the real implementation is linked

extern "C" {
    // Weak vtable symbols (may not be needed, but here for completeness)
    __attribute__((weak))
    void _ZTV18PhiImageProcessor() {
        // Empty vtable implementation
    }
    
    __attribute__((weak))
    void _ZTV20GemmaImageProcessor() {
        // Empty vtable implementation  
    }
}
