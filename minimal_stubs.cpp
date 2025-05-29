// minimal_stubs.cpp
// Only provide the missing function implementations that are causing linker errors

#include <stdexcept>
#include <memory>
#include <string>

// Forward declarations only - don't redefine classes
namespace Generators {
    class State;
    class Images;
    class Audios;
    class NamedTensors;
    class WindowedKeyValueCache;
    class MultiModalProcessor;
}

// Provide only the missing implementations
namespace Generators {

// WindowedKeyValueCache constructor implementation
WindowedKeyValueCache::WindowedKeyValueCache(State&) {
    // Empty implementation for text-only build
    // In real implementation, this would set up windowed key-value caching
}

// MultiModalProcessor::Process implementation  
std::unique_ptr<NamedTensors> MultiModalProcessor::Process(const std::string&, const Images*, const Audios*) const {
    // Throw error since multimedia processing not supported in text-only build
    throw std::runtime_error("MultiModalProcessor::Process not supported in text-only build");
}

} // namespace Generators

// Provide stub implementations for missing global functions
namespace Generators {

// Device interface stubs
class DeviceInterface;

DeviceInterface* GetQNNInterface() {
    return nullptr;
}

DeviceInterface* GetWebGPUInterface() {
    return nullptr;
}

DeviceInterface* GetOpenVINOInterface() {
    return nullptr;
}

// Multimedia loading stubs
class OrtxObject;

std::unique_ptr<OrtxObject> LoadImages(std::span<const char* const>) {
    throw std::runtime_error("LoadImages not supported in text-only build");
}

std::unique_ptr<OrtxObject> LoadAudios(std::span<const char* const> const&) {
    throw std::runtime_error("LoadAudios not supported in text-only build");
}

std::unique_ptr<OrtxObject> LoadImagesFromBuffers(std::span<const void*>, std::span<const unsigned long>) {
    throw std::runtime_error("LoadImagesFromBuffers not supported in text-only build");
}

std::unique_ptr<OrtxObject> LoadAudiosFromBuffers(std::span<const void*>, std::span<const unsigned long>) {
    throw std::runtime_error("LoadAudiosFromBuffers not supported in text-only build");
}

// Guidance processor stub
std::unique_ptr<void> CreateGuidanceLogitsProcessor(const State&) {
    return nullptr;
}

// Model compatibility check
class Model;
bool IsOpenVINOStatefulModel(const Model&) {
    return false;
}

} // namespace Generators

// C API stubs for ONNX Runtime Extensions
extern "C" {

typedef enum {
    kOrtxOK = 0,
    kOrtxErrorInvalidArgument = 1,
    kOrtxErrorOutOfMemory = 2
} extError_t;

const extError_t kOrtxOK = (extError_t)0;

// Provide minimal stubs for the C API functions
extError_t OrtxCreate(const char*, void**) {
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxCreateTokenizer(void**, const char*) {
    return kOrtxErrorInvalidArgument; // Not supported in text-only build  
}

extError_t OrtxTokenizeWithOptions(void*, const char**, int, void**, int) {
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxDetokenize1D(void*, const unsigned int*, size_t, void**) {
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxDetokenizeCached(void*, void*, int, const char**) {
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxApplyChatTemplate(void*, const char*, const char*, const char*, void**, int, int) {
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxConvertTokenToId(void*, const char*, unsigned int*) {
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

void OrtxDispose(void*) {
    // Empty stub
}

void OrtxDisposeOnly(void*) {
    // Empty stub  
}

const char* OrtxGetLastErrorMessage() {
    return "ONNX Runtime Extensions not available - text-only build";
}

extError_t OrtxGetTensorData(void*, const void**, size_t*, size_t*) {
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxStringArrayGetItem(void*, size_t, const char**) {
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxTensorResultGetAt(void*, size_t, void**) {
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

extError_t OrtxTokenId2DArrayGetItem(void*, size_t, const unsigned int**, size_t*) {
    return kOrtxErrorInvalidArgument; // Not supported in text-only build
}

} // extern "C"