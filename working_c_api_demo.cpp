// working_c_api_demo.cpp - Uses stable C API instead of C++ wrapper

#include <iostream>
#include <string>
#include <chrono>
#include <vector>

// Use the C API which is more stable
#include "ort_genai_c.h"

class Phi3CDemo {
private:
    OgaModel* model_;
    OgaTokenizer* tokenizer_;
    std::string model_path_;
    
public:
    explicit Phi3CDemo(const std::string& model_path) 
        : model_(nullptr), tokenizer_(nullptr), model_path_(model_path) {}
    
    ~Phi3CDemo() {
        if (tokenizer_) OgaDestroyTokenizer(tokenizer_);
        if (model_) OgaDestroyModel(model_);
    }
    
    bool Initialize() {
        try {
            std::cout << "🔧 Loading Phi-3 model from: " << model_path_ << std::endl;
            
            // Load the model using C API
            OgaResult* result = OgaCreateModel(model_path_.c_str(), &model_);
            if (!model_ || result) {
                std::cerr << "❌ Failed to load model from: " << model_path_ << std::endl;
                if (result) {
                    const char* error_msg = OgaResultGetError(result);
                    std::cerr << "Error: " << (error_msg ? error_msg : "Unknown error") << std::endl;
                    OgaDestroyResult(result);
                }
                return false;
            }
            
            std::cout << "✅ Model loaded successfully!" << std::endl;
            
            // Create tokenizer using C API
            result = OgaCreateTokenizer(model_, &tokenizer_);
            if (!tokenizer_ || result) {
                std::cerr << "❌ Failed to create tokenizer" << std::endl;
                if (result) {
                    const char* error_msg = OgaResultGetError(result);
                    std::cerr << "Error: " << (error_msg ? error_msg : "Unknown error") << std::endl;
                    OgaDestroyResult(result);
                }
                return false;
            }
            
            std::cout << "✅ Tokenizer created successfully!" << std::endl;
            return true;
            
        } catch (const std::exception& e) {
            std::cerr << "❌ Exception during initialization: " << e.what() << std::endl;
            return false;
        }
    }
    
    std::string Generate(const std::string& prompt, int max_length = 100) {
        if (!model_ || !tokenizer_) {
            return "Error: Model not initialized";
        }
        
        try {
            std::cout << "\n💭 Processing: \"" << prompt << "\"" << std::endl;
            
            auto start_time = std::chrono::high_resolution_clock::now();
            
            // Create sequences and encode prompt
            OgaSequences* sequences = nullptr;
            OgaResult* result = OgaCreateSequences(&sequences);
            if (result) {
                return "Error: Failed to create sequences";
            }
            
            result = OgaTokenizerEncode(tokenizer_, prompt.c_str(), sequences);
            if (result) {
                OgaDestroySequences(sequences);
                return "Error: Failed to encode prompt";
            }
            
            std::cout << "🔤 Tokenized input" << std::endl;
            
            // Create generator parameters
            OgaGeneratorParams* params = nullptr;
            result = OgaCreateGeneratorParams(model_, &params);
            if (result) {
                OgaDestroySequences(sequences);
                return "Error: Failed to create generator params";
            }
            
            // Set search options
            result = OgaGeneratorParamsSetSearchOption(params, "max_length", max_length);
            if (result) {
                std::cout << "⚠️ Warning: Failed to set max_length" << std::endl;
            }
            
            result = OgaGeneratorParamsSetSearchOptionBool(params, "do_sample", false);
            if (result) {
                std::cout << "⚠️ Warning: Failed to set do_sample" << std::endl;
            }
            
            // Set input sequences
            result = OgaGeneratorParamsSetInputSequences(params, sequences);
            if (result) {
                OgaDestroyGeneratorParams(params);
                OgaDestroySequences(sequences);
                return "Error: Failed to set input sequences";
            }
            
            std::cout << "⚙️ Generation parameters set" << std::endl;
            
            // Create generator
            OgaGenerator* generator = nullptr;
            result = OgaCreateGenerator(model_, params, &generator);
            if (result) {
                OgaDestroyGeneratorParams(params);
                OgaDestroySequences(sequences);
                return "Error: Failed to create generator";
            }
            
            std::cout << "🧠 Generating..." << std::endl;
            
            // Generate tokens
            while (!OgaGenerator_IsDone(generator)) {
                result = OgaGenerator_ComputeLogits(generator);
                if (result) {
                    std::cout << "⚠️ Warning: ComputeLogits failed" << std::endl;
                }
                
                result = OgaGenerator_GenerateNextToken(generator);
                if (result) {
                    std::cout << "⚠️ Warning: GenerateNextToken failed" << std::endl;
                    break;
                }
                
                // Print progress
                std::cout << "." << std::flush;
            }
            
            std::cout << std::endl;
            
            // Get the result
            const int32_t* output_sequence = OgaGenerator_GetSequenceData(generator, 0);
            size_t output_length = OgaGenerator_GetSequenceCount(generator, 0);
            
            if (!output_sequence || output_length == 0) {
                OgaDestroyGenerator(generator);
                OgaDestroyGeneratorParams(params);
                OgaDestroySequences(sequences);
                return "Error: No output generated";
            }
            
            // Decode the output
            OgaString* decoded_string = nullptr;
            result = OgaTokenizerDecode(tokenizer_, output_sequence, output_length, &decoded_string);
            
            std::string final_result;
            if (!result && decoded_string) {
                const char* str_data = OgaStringGetString(decoded_string);
                if (str_data) {
                    final_result = std::string(str_data);
                }
                OgaDestroyString(decoded_string);
            }
            
            // Cleanup
            OgaDestroyGenerator(generator);
            OgaDestroyGeneratorParams(params);
            OgaDestroySequences(sequences);
            
            auto end_time = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
            
            std::cout << "⚡ Generated in " << duration.count() << "ms" << std::endl;
            
            return final_result.empty() ? "Generated response (decode failed)" : final_result;
            
        } catch (const std::exception& e) {
            return std::string("Error: ") + e.what();
        }
    }
    
    void RunInteractiveDemo() {
        std::cout << "\n🎮 Interactive Phi-3 Demo (C API)" << std::endl;
        std::cout << "Type your prompts (or 'quit' to exit, 'help' for commands)" << std::endl;
        std::cout << "====================================================\n" << std::endl;
        
        std::string input;
        while (true) {
            std::cout << "You: ";
            std::getline(std::cin, input);
            
            if (input == "quit" || input == "exit") {
                std::cout << "👋 Goodbye!" << std::endl;
                break;
            }
            
            if (input == "help") {
                ShowHelp();
                continue;
            }
            
            if (input.empty()) {
                continue;
            }
            
            std::string response = Generate(input, 200);
            std::cout << "\n🤖 Phi-3: " << response << std::endl;
            std::cout << std::string(60, '-') << std::endl;
        }
    }
    
    void ShowHelp() {
        std::cout << "\n📖 Available commands:" << std::endl;
        std::cout << "  help - Show this help message" << std::endl;
        std::cout << "  quit - Exit the demo" << std::endl;
        std::cout << "  Any other text - Generate AI response" << std::endl;
        std::cout << "\n💡 Try prompts like:" << std::endl;
        std::cout << "  - What is machine learning?" << std::endl;
        std::cout << "  - Explain quantum computing in simple terms" << std::endl;
        std::cout << "  - Write a short poem about AI" << std::endl << std::endl;
    }
    
    void RunBenchmark() {
        std::vector<std::string> test_prompts = {
            "What is artificial intelligence?",
            "Explain machine learning briefly.",
            "How do computers work?",
            "What is the future of technology?",
            "Describe renewable energy."
        };
        
        std::cout << "\n🏁 Running benchmark with " << test_prompts.size() << " prompts..." << std::endl;
        
        auto total_start = std::chrono::high_resolution_clock::now();
        std::vector<double> times;
        
        for (size_t i = 0; i < test_prompts.size(); ++i) {
            std::cout << "\n📝 Test " << (i + 1) << "/" << test_prompts.size() << std::endl;
            
            auto start = std::chrono::high_resolution_clock::now();
            std::string result = Generate(test_prompts[i], 100);
            auto end = std::chrono::high_resolution_clock::now();
            
            auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
            times.push_back(duration.count());
            
            std::cout << "📄 Response length: " << result.length() << " characters" << std::endl;
        }
        
        auto total_end = std::chrono::high_resolution_clock::now();
        auto total_duration = std::chrono::duration_cast<std::chrono::milliseconds>(total_end - total_start);
        
        // Calculate statistics
        double total_time = 0;
        for (double t : times) total_time += t;
        double avg_time = total_time / times.size();
        
        std::cout << "\n🏆 Benchmark Results:" << std::endl;
        std::cout << "Total time: " << total_duration.count() << "ms" << std::endl;
        std::cout << "Average per prompt: " << avg_time << "ms" << std::endl;
        std::cout << "Prompts per minute: " << (60000.0 / avg_time) << std::endl;
    }
};

int main(int argc, char* argv[]) {
    std::cout << "🚀 Phi-3 C API Demo for macOS" << std::endl;
    std::cout << "Static build with stable C API" << std::endl;
    std::cout << "===============================" << std::endl;
    
    if (argc < 2) {
        std::cout << "\nUsage: " << argv[0] << " <model_path> [mode]" << std::endl;
        std::cout << "\nModes:" << std::endl;
        std::cout << "  interactive (default) - Interactive chat" << std::endl;
        std::cout << "  benchmark            - Performance test" << std::endl;
        std::cout << "  single <prompt>      - One-shot generation" << std::endl;
        std::cout << "\nExample:" << std::endl;
        std::cout << "  " << argv[0] << " model.onnx" << std::endl;
        std::cout << "  " << argv[0] << " model.onnx benchmark" << std::endl;
        std::cout << "  " << argv[0] << " model.onnx single \"What is AI?\"" << std::endl;
        return 1;
    }
    
    std::string model_path = argv[1];
    std::string mode = (argc >= 3) ? argv[2] : "interactive";
    
    try {
        Phi3CDemo demo(model_path);
        
        if (!demo.Initialize()) {
            std::cerr << "❌ Failed to initialize demo" << std::endl;
            return 1;
        }
        
        if (mode == "interactive") {
            demo.RunInteractiveDemo();
        } else if (mode == "benchmark") {
            demo.RunBenchmark();
        } else if (mode == "single" && argc >= 4) {
            std::string prompt = argv[3];
            std::cout << "\n🤖 Response: " << demo.Generate(prompt, 200) << std::endl;
        } else {
            std::cerr << "❌ Invalid mode or missing prompt" << std::endl;
            return 1;
        }
        
    } catch (const std::exception& e) {
        std::cerr << "💥 Fatal error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}