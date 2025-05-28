// simple_c_demo.cpp - Minimal C API demo that should work

#include <iostream>
#include <string>
#include <chrono>

// Use only the most basic C API functions
#include "ort_genai_c.h"

class SimplePhi3Demo {
private:
    OgaModel* model_;
    OgaTokenizer* tokenizer_;
    std::string model_path_;
    
public:
    explicit SimplePhi3Demo(const std::string& model_path) 
        : model_(nullptr), tokenizer_(nullptr), model_path_(model_path) {}
    
    ~SimplePhi3Demo() {
        if (tokenizer_) OgaDestroyTokenizer(tokenizer_);
        if (model_) OgaDestroyModel(model_);
    }
    
    bool Initialize() {
        std::cout << "🔧 Loading model from: " << model_path_ << std::endl;
        
        // Load model
        OgaResult* result = OgaCreateModel(model_path_.c_str(), &model_);
        if (result) {
            std::cerr << "❌ Failed to load model" << std::endl;
            const char* error = OgaResultGetError(result);
            if (error) std::cerr << "Error: " << error << std::endl;
            OgaDestroyResult(result);
            return false;
        }
        
        if (!model_) {
            std::cerr << "❌ Model is null" << std::endl;
            return false;
        }
        
        std::cout << "✅ Model loaded!" << std::endl;
        
        // Create tokenizer
        result = OgaCreateTokenizer(model_, &tokenizer_);
        if (result) {
            std::cerr << "❌ Failed to create tokenizer" << std::endl;
            const char* error = OgaResultGetError(result);
            if (error) std::cerr << "Error: " << error << std::endl;
            OgaDestroyResult(result);
            return false;
        }
        
        if (!tokenizer_) {
            std::cerr << "❌ Tokenizer is null" << std::endl;
            return false;
        }
        
        std::cout << "✅ Tokenizer created!" << std::endl;
        return true;
    }
    
    std::string Generate(const std::string& prompt) {
        if (!model_ || !tokenizer_) {
            return "Error: Not initialized";
        }
        
        try {
            std::cout << "\n💭 Processing: \"" << prompt << "\"" << std::endl;
            auto start_time = std::chrono::high_resolution_clock::now();
            
            // Step 1: Create sequences
            OgaSequences* sequences = nullptr;
            OgaResult* result = OgaCreateSequences(&sequences);
            if (result) {
                std::cerr << "Failed to create sequences" << std::endl;
                OgaDestroyResult(result);
                return "Error creating sequences";
            }
            
            // Step 2: Encode the prompt
            result = OgaTokenizerEncode(tokenizer_, prompt.c_str(), sequences);
            if (result) {
                std::cerr << "Failed to encode prompt" << std::endl;
                OgaDestroyResult(result);
                OgaDestroySequences(sequences);
                return "Error encoding prompt";
            }
            
            std::cout << "🔤 Encoded prompt" << std::endl;
            
            // Step 3: Create generator parameters
            OgaGeneratorParams* params = nullptr;
            result = OgaCreateGeneratorParams(model_, &params);
            if (result) {
                std::cerr << "Failed to create params" << std::endl;
                OgaDestroyResult(result);
                OgaDestroySequences(sequences);
                return "Error creating params";
            }
            
            // Step 4: Try to set some basic options (ignore failures)
            OgaGeneratorParamsSetSearchBool(params, "do_sample", false);
            
            std::cout << "⚙️ Created generation params" << std::endl;
            
            // Step 5: Create generator
            OgaGenerator* generator = nullptr;
            result = OgaCreateGenerator(model_, params, &generator);
            if (result) {
                std::cerr << "Failed to create generator" << std::endl;
                OgaDestroyResult(result);
                OgaDestroyGeneratorParams(params);
                OgaDestroySequences(sequences);
                return "Error creating generator";
            }
            
            std::cout << "🧠 Starting generation..." << std::endl;
            
            // Step 6: Generate (simple approach)
            int token_count = 0;
            const int max_tokens = 50; // Keep it small for testing
            
            while (!OgaGenerator_IsDone(generator) && token_count < max_tokens) {
                result = OgaGenerator_GenerateNextToken(generator);
                if (result) {
                    std::cout << "\n⚠️ Generation stopped early" << std::endl;
                    OgaDestroyResult(result);
                    break;
                }
                token_count++;
                std::cout << "." << std::flush;
            }
            
            std::cout << "\n📝 Generated " << token_count << " tokens" << std::endl;
            
            // Step 7: Get output
            const int32_t* output_data = OgaGenerator_GetSequenceData(generator, 0);
            size_t output_length = OgaGenerator_GetSequenceCount(generator, 0);
            
            std::string result_text = "Generated " + std::to_string(output_length) + " tokens";
            
            if (output_data && output_length > 0) {
                // Try to decode
                const char* decoded = nullptr;
                OgaResult* decode_result = OgaTokenizerDecode(tokenizer_, output_data, output_length, &decoded);
                
                if (!decode_result && decoded) {
                    result_text = std::string(decoded);
                } else {
                    result_text = "Generated text (decode failed): " + std::to_string(output_length) + " tokens";
                    if (decode_result) OgaDestroyResult(decode_result);
                }
            }
            
            // Cleanup
            OgaDestroyGenerator(generator);
            OgaDestroyGeneratorParams(params);
            OgaDestroySequences(sequences);
            
            auto end_time = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
            std::cout << "⚡ Completed in " << duration.count() << "ms" << std::endl;
            
            return result_text;
            
        } catch (const std::exception& e) {
            return std::string("Exception: ") + e.what();
        }
    }
    
    void RunTest() {
        std::cout << "\n🧪 Running simple test..." << std::endl;
        
        std::vector<std::string> test_prompts = {
            "Hello",
            "What is AI?",
            "The sky is"
        };
        
        for (const auto& prompt : test_prompts) {
            std::cout << "\n" << std::string(50, '=') << std::endl;
            std::string response = Generate(prompt);
            std::cout << "Response: " << response << std::endl;
        }
    }
};

int main(int argc, char* argv[]) {
    std::cout << "🚀 Simple Phi-3 C API Test" << std::endl;
    std::cout << "Basic functionality test" << std::endl;
    std::cout << "========================" << std::endl;
    
    if (argc < 2) {
        std::cout << "Usage: " << argv[0] << " <model_path>" << std::endl;
        return 1;
    }
    
    try {
        SimplePhi3Demo demo(argv[1]);
        
        if (!demo.Initialize()) {
            std::cerr << "❌ Initialization failed" << std::endl;
            return 1;
        }
        
        demo.RunTest();
        
        std::cout << "\n🎉 Test completed!" << std::endl;
        
    } catch (const std::exception& e) {
        std::cerr << "💥 Fatal error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}