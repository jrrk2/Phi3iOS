#include <string>

// Minimal stubs for text-only GenAI
namespace Generators {
    struct DeviceInterface;
    class Model;
    DeviceInterface* GetQNNInterface() { return nullptr; }
    DeviceInterface* GetWebGPUInterface() { return nullptr; }
    DeviceInterface* GetOpenVINOInterface() { return nullptr; }
    bool IsOpenVINOStatefulModel(const Model& model) { return false; }
}

// Normalizer stub for text processing
namespace ort_extensions {
    namespace normalizer {
      //        std::string Search(const std::string& text) { return text; }
    }
}
