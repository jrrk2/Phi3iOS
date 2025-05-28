// multimedia_stubs.cpp
// Stub implementations for multimedia functions we don't need for text-only operation on iOS

#include <stdexcept>
#include <span>
#include <memory>

#include "../onnxruntime-genai/src/models/model.h"
#include "../onnxruntime-genai/src/ort_genai_c.h"

// Forward declarations
namespace Generators {

    extern "C" {
        void __force_link_stubs() {
            // This function forces the linker to include our stub implementations
            static WindowedKeyValueCache* dummy1 = nullptr;
            static MultiModalProcessor* dummy2 = nullptr;
            (void)dummy1;
            (void)dummy2;
        }
    }

// Image/Audio loading stubs - these will throw if called
std::unique_ptr<OrtxObject> LoadImages(std::span<const char* const>) {
    throw std::runtime_error("Image loading not supported in text-only iOS build");
}

std::unique_ptr<OrtxObject> LoadAudios(std::span<const char* const> const&) {
    throw std::runtime_error("Audio loading not supported in text-only iOS build");
}

std::unique_ptr<OrtxObject> LoadImagesFromBuffers(std::span<const void*>, std::span<const unsigned long>) {
    throw std::runtime_error("Image buffer loading not supported in text-only iOS build");
}

std::unique_ptr<OrtxObject> LoadAudiosFromBuffers(std::span<const void*>, std::span<const unsigned long>) {
    throw std::runtime_error("Audio buffer loading not supported in text-only iOS build");
}

// Device interface stubs - return null for unsupported devices on iOS
class DeviceInterface;

DeviceInterface* GetQNNInterface() {
    return nullptr; // QNN not supported on iOS
}

DeviceInterface* GetWebGPUInterface() {
    return nullptr; // WebGPU not supported on iOS
}

DeviceInterface* GetOpenVINOInterface() {
    return nullptr; // OpenVINO not supported on iOS
}

// Multimedia processing stubs
template<typename T>
std::unique_ptr<OrtValue, std::default_delete<OrtValue>> ProcessTensor(OrtxObject*, Ort::Allocator&) {
    throw std::runtime_error("Tensor processing not supported in text-only iOS build");
}

// Explicit template instantiations for the types we saw in linker errors
template std::unique_ptr<OrtValue, std::default_delete<OrtValue>> ProcessTensor<float>(OrtxObject*, Ort::Allocator&);
template std::unique_ptr<OrtValue, std::default_delete<OrtValue>> ProcessTensor<bool>(OrtxObject*, Ort::Allocator&);
template std::unique_ptr<OrtValue, std::default_delete<OrtValue>> ProcessTensor<long long>(OrtxObject*, Ort::Allocator&);
template std::unique_ptr<OrtValue, std::default_delete<OrtValue>> ProcessTensor<Ort::Float16_t>(OrtxObject*, Ort::Allocator&);

// Guidance logits processor stub
std::unique_ptr<void> CreateGuidanceLogitsProcessor(const State&) {
    return nullptr; // No guidance processor needed for basic generation
}

// Missing processor classes - provide stub implementations
class WhisperProcessor {
public:
    WhisperProcessor(Config&, const SessionInfo&) {
        throw std::runtime_error("WhisperProcessor not supported in text-only iOS build");
    }
    virtual ~WhisperProcessor() = default;
};

class PhiImageProcessor {
public:
    PhiImageProcessor(Config&, const SessionInfo&) {
        throw std::runtime_error("PhiImageProcessor not supported in text-only iOS build");
    }
    virtual ~PhiImageProcessor() = default;
};

class GemmaImageProcessor {
public:
    GemmaImageProcessor(Config&, const SessionInfo&) {
        throw std::runtime_error("GemmaImageProcessor not supported in text-only iOS build");
    }
    virtual ~GemmaImageProcessor() = default;
};

class PhiMultiModalProcessor {
public:
    PhiMultiModalProcessor(Config&, const SessionInfo&) {
        throw std::runtime_error("PhiMultiModalProcessor not supported in text-only iOS build");
    }
    virtual ~PhiMultiModalProcessor() = default;
};

// Missing model classes
class Whisper_Model {
public:
    Whisper_Model(std::unique_ptr<Config>, struct OrtEnv&) {
        throw std::runtime_error("Whisper_Model not supported in text-only iOS build");
    }
};

class MultiModalLanguageModel {
public:
    MultiModalLanguageModel(std::unique_ptr<Config>, struct OrtEnv&, bool, bool) {
        throw std::runtime_error("MultiModalLanguageModel not supported in text-only iOS build");
    }
};

// Embeddings and MultiModal stubs for iOS
class Embeddings {
public:
    enum class Mode { Input, Output };
    Embeddings(State&, Mode, const std::string&) {}
    void Add() {}
    void UpdateSequenceLength(unsigned long) {}
    void ReuseEmbeddingsBuffer(const Embeddings&) {}
};

class MultiModalFeatures {
public:
    enum class Mode { Vision, Speech, Embedding };
    MultiModalFeatures(State&, Mode, const std::string&, long long, long long) {}
    void Add() {}
    void Update(bool) {}
    void ReuseFeaturesBuffer(MultiModalFeatures&) {}
};

// WindowedKeyValueCache implementation
class WindowedKeyValueCache {
public:
    WindowedKeyValueCache(State&) {}
};

// OpenVINO specific functions (not available on iOS)
bool IsOpenVINOStatefulModel(const Model&) {
    return false; // Not using OpenVINO on iOS
}

} // namespace Generators

// C API stubs for missing Ortx functions (these need custom operators)
extern "C" {

void* OrtxCreate(const char*) {
    return nullptr; // Stub - requires custom operators
}

void* OrtxCreateTokenizer(void*, const char*) {
    return nullptr; // Stub - requires custom operators  
}

int OrtxTokenizeWithOptions(void*, const char*, void*, void*) {
    return -1; // Stub - requires custom operators
}

int OrtxDetokenize1D(void*, const int*, size_t, char**) {
    return -1; // Stub - requires custom operators
}

int OrtxDetokenizeCached(void*, void*, char**) {
    return -1; // Stub - requires custom operators
}

int OrtxApplyChatTemplate(void*, const char*, char**) {
    return -1; // Stub - requires custom operators
}

int OrtxConvertTokenToId(void*, const char*) {
    return -1; // Stub - requires custom operators
}

void OrtxDispose(void*) {
    // Stub - requires custom operators
}

void OrtxDisposeOnly(void*) {
    // Stub - requires custom operators
}

const char* OrtxGetLastErrorMessage() {
    return "Custom operators not available in this build";
}

void* OrtxGetTensorData(void*) {
    return nullptr; // Stub - requires custom operators
}

const char* OrtxStringArrayGetItem(void*, size_t) {
    return nullptr; // Stub - requires custom operators
}

void* OrtxTensorResultGetAt(void*, size_t) {
    return nullptr; // Stub - requires custom operators
}

const int* OrtxTokenId2DArrayGetItem(void*, size_t, size_t*) {
    return nullptr; // Stub - requires custom operators
}

} // extern "C"
