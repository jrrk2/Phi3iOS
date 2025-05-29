// multimedia_stubs.cpp
// Stub implementations for multimedia functions we don't need for text-only operation

#include <stdexcept>
#include <span>
#include <memory>

// Forward declarations
class OrtxObject;

namespace Generators {

// Image/Audio loading stubs - these will throw if called
std::unique_ptr<OrtxObject> LoadImages(std::span<const char* const>) {
    throw std::runtime_error("Image loading not supported in text-only build");
}

std::unique_ptr<OrtxObject> LoadAudios(std::span<const char* const> const&) {
    throw std::runtime_error("Audio loading not supported in text-only build");
}

std::unique_ptr<OrtxObject> LoadImagesFromBuffers(std::span<const void*>, std::span<const unsigned long>) {
    throw std::runtime_error("Image buffer loading not supported in text-only build");
}

std::unique_ptr<OrtxObject> LoadAudiosFromBuffers(std::span<const void*>, std::span<const unsigned long>) {
    throw std::runtime_error("Audio buffer loading not supported in text-only build");
}

// Device interface stubs - return null for unsupported devices
class DeviceInterface;

DeviceInterface* GetQNNInterface() {
    return nullptr; // QNN not supported
}

DeviceInterface* GetWebGPUInterface() {
    return nullptr; // WebGPU not supported
}

DeviceInterface* GetOpenVINOInterface() {
    return nullptr; // OpenVINO not supported
}

// Multimedia processing stubs
template<typename T>
std::unique_ptr<struct OrtValue, std::default_delete<struct OrtValue>> ProcessTensor(OrtxObject*, struct Ort::Allocator&) {
    throw std::runtime_error("Tensor processing not supported in text-only build");
}

// Explicit template instantiations for the types we saw in linker errors
namespace Ort { class Float16_t; }
template std::unique_ptr<struct OrtValue, std::default_delete<struct OrtValue>> ProcessTensor<float>(OrtxObject*, struct Ort::Allocator&);
template std::unique_ptr<struct OrtValue, std::default_delete<struct OrtValue>> ProcessTensor<bool>(OrtxObject*, struct Ort::Allocator&);
template std::unique_ptr<struct OrtValue, std::default_delete<struct OrtValue>> ProcessTensor<long long>(OrtxObject*, struct Ort::Allocator&);
template std::unique_ptr<struct OrtValue, std::default_delete<struct OrtValue>> ProcessTensor<Ort::Float16_t>(OrtxObject*, struct Ort::Allocator&);

// Guidance logits processor stub
class State;
std::unique_ptr<void> CreateGuidanceLogitsProcessor(const State&) {
    return nullptr; // No guidance processor needed for basic generation
}

// Embeddings and MultiModal stubs
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

// WindowedKeyValueCache stub
class WindowedKeyValueCache {
public:
    WindowedKeyValueCache(State&) {}
};

// OpenVINO specific functions
class Model;
bool IsOpenVINOStatefulModel(const Model&) {
    return false; // Not using OpenVINO
}

} // namespace Generators