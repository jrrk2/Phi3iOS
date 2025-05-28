// static_implementations.cpp - iOS-compatible implementations

#include <string>
#include <vector>
#include <memory>
#include <iostream>

// Minimal static implementations for iOS compatibility

namespace Generators {
    struct DeviceInterface;
    class Model;
    class State;
    
    // Device interface stubs (static)
    DeviceInterface* GetQNNInterface() { return nullptr; }
    DeviceInterface* GetWebGPUInterface() { return nullptr; }
    DeviceInterface* GetOpenVINOInterface() { return nullptr; }
    bool IsOpenVINOStatefulModel(const Model& model) { return false; }
    
    // Static KV cache implementation
    class StaticKeyValueCache {
    public:
        StaticKeyValueCache(State& state) {
            std::cout << "Using static KV cache (iOS build)" << std::endl;
        }
    };
    
    void* CreateKeyValueCache(State& state) {
        return new StaticKeyValueCache(state);
    }
}

// Static tokenizer implementation (no dynamic dependencies)
namespace ort_extensions {
    namespace normalizer {
        std::string Search(const std::string& text) { 
            return text; // Pass through
        }
    }
}

// Static C API stubs
extern "C" {
    void* OrtxCreateProcessor(void** processor, void* ort_env, const char* config_path) {
        if (processor) *processor = nullptr;
        return nullptr;
    }
}

// Base64 stub (static)
void base64_decode(const std::string& input, std::vector<unsigned char>& output) {
    output.clear();
}

// Initialization message
namespace {
    struct StaticInit {
        StaticInit() {
            std::cout << "🍎 iOS-compatible static GenAI build initialized" << std::endl;
        }
    };
    static StaticInit init;
}
