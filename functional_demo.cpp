// functional_demo.cpp - Working GenAI demo for macOS

#include <iostream>
#include <string>
#include <memory>
#include <chrono>
#include <vector>

// Include ONNX Runtime GenAI headers
#include "ort_genai.h"

class Phi3Demo {
private:
    std::unique_ptr<OgaModel> model_;
    std::unique_ptr<OgaTokenizer> tokenizer_;
    std::string model_path_;
    
public:
    explicit Phi3Demo(const std::string& model_path) : model_path_(model_path) {}
    
    bool Initialize() {
        try {
            std::cout << "🔧 Loading Phi-3 model from: " << model_path_ << std::endl;
            
            // Load the model
            model_ = OgaModel::Create(model_path_.c_str());
            if (!model_) {
                std::cerr << "❌ Failed to load model from: " << model_path_ << std::endl;
                return false;
            }
            
            std::cout << "✅ Model loaded successfully!" << std::endl;
            
            // Create tokenizer
            tokenizer_ = OgaTokenizer::Create(*model_);
            if (!tokenizer_) {
                std::cerr << "❌ Failed to create tokenizer" << std::endl;
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
            
            // Create generator parameters first
            auto params = OgaGeneratorParams::Create(*model_);
            params->SetSearchOption("max_length", max_length);
            params->SetSearchOption("do_sample", false);  // Greedy decoding
            
            // Try the prompt method
            params->TryGraphCaptureWithMaxLength(1024);
            
            std::cout << "⚙️ Generation parameters set" << std::endl;
            
            // Create generator
            auto generator = OgaGenerator::Create(*model_, *params);
            
            // Set the prompt
            tokenizer_->Encode(prompt.c_str(), generator->GetSequence(0));
            
            std::cout << "🔤 Prompt set and tokenized" << std::endl;
            std::cout << "🧠 Generating..." << std::endl;
            
            while (!generator->IsDone()) {
                generator->GenerateNextToken();
                
                // Print a dot for progress
                std::cout << "." << std::flush;
            }
            
            std::cout << std::endl;
            
            // Get the generated sequence and decode
            auto output_sequence = generator->GetSequence(0);
            auto decoded_string = tokenizer_->Decode(output_sequence);
            std::string result(decoded_string);
            
            auto end_time = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
            
            std::cout << "⚡ Generated in " << duration.count() << "ms" << std::endl;
            
            return result;
            
        } catch (const std::exception& e) {
            return std::string("Error: ") + e.what();
        }
    }
    
    void RunInteractiveDemo() {
        std::cout << "\n🎮 Interactive Phi-3 Demo" << std::endl;
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
            "Explain the concept of machine learning.",
            "How do neural networks work?",
            "What are the benefits of renewable energy?",
            "Describe the future of space exploration."
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
    std::cout << "🚀 Phi-3 Functional Demo for macOS" << std::endl;
    std::cout << "Static build with ONNX Runtime GenAI" << std::endl;
    std::cout << "====================================" << std::endl;
    
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
        Phi3Demo demo(model_path);
        
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