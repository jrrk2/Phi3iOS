#include <iostream>
#include <string>
#include <vector>
#include <memory>

// Include the ONNX Runtime GenAI C API header
#include "ort_genai_c.h"

int generateResponse(const std::string& user_input, 
                    OgaModel* model, 
                    OgaTokenizer* tokenizer, 
                    OgaTokenizerStream* tokenizer_stream) {
    
    std::cout << "📝 You: " << user_input << "\n";
    
    // Format with Phi-3 chat template
    std::string chat_template = "<|user|>\n";
    chat_template += user_input;
    chat_template += " <|end|>\n<|assistant|>";
    
    // Encode the prompt
    OgaSequences* input_sequences = nullptr;
    if (OgaCreateSequences(&input_sequences) != nullptr) {
        std::cerr << "❌ Failed to create sequences\n";
        return -1;
    }
    
    if (OgaTokenizerEncode(tokenizer, chat_template.c_str(), input_sequences) != nullptr) {
        std::cerr << "❌ Failed to encode prompt\n";
        OgaDestroySequences(input_sequences);
        return -1;
    }
    
    // Create generator parameters
    OgaGeneratorParams* params = nullptr;
    if (OgaCreateGeneratorParams(model, &params) != nullptr) {
        std::cerr << "❌ Failed to create generator params\n";
        OgaDestroySequences(input_sequences);
        return -1;
    }
    
    // Set generation parameters
    OgaGeneratorParamsSetSearchNumber(params, "max_length", 500.0);
    OgaGeneratorParamsSetSearchNumber(params, "batch_size", 1.0);
    
    // Create generator
    OgaGenerator* generator = nullptr;
    if (OgaCreateGenerator(model, params, &generator) != nullptr) {
        std::cerr << "❌ Failed to create generator\n";
        OgaDestroyGeneratorParams(params);
        OgaDestroySequences(input_sequences);
        return -1;
    }
    
    // Append input tokens
    if (OgaGenerator_AppendTokenSequences(generator, input_sequences) != nullptr) {
        std::cerr << "❌ Failed to append tokens\n";
        OgaDestroyGenerator(generator);
        OgaDestroyGeneratorParams(params);
        OgaDestroySequences(input_sequences);
        return -1;
    }
    
    // Generate response
    std::cout << "🤖 Phi-3: ";
    std::cout.flush();
    
    std::string response;
    int token_count_generated = 0;
    const int max_tokens = 200;
    
    while (!OgaGenerator_IsDone(generator) && token_count_generated < max_tokens) {
        if (OgaGenerator_GenerateNextToken(generator) != nullptr) {
            std::cerr << "\n❌ Failed to generate next token\n";
            break;
        }
        
        // Get the next tokens
        const int32_t* tokens = nullptr;
        size_t token_count = 0;
        
        if (OgaGenerator_GetNextTokens(generator, &tokens, &token_count) != nullptr) {
            std::cerr << "\n❌ Failed to get next tokens\n";
            break;
        }
        
        if (token_count > 0) {
            int32_t new_token = tokens[token_count - 1];
            
            // Decode the token
            const char* token_text = nullptr;
            if (OgaTokenizerStreamDecode(tokenizer_stream, new_token, &token_text) == nullptr) {
                std::cout << token_text;
                std::cout.flush();
                response += token_text;
                
                // Check for end token
                if (std::string(token_text).find("<|end|>") != std::string::npos) {
                    break;
                }
            }
        }
        
        token_count_generated++;
    }
    
    std::cout << "\n\n";
    
    // Cleanup
    OgaDestroyGenerator(generator);
    OgaDestroyGeneratorParams(params);
    OgaDestroySequences(input_sequences);
    
    return 0;
}

int main() {
    std::cout << "🚀 Interactive Phi-3 Chat with ONNX Runtime GenAI C API\n";
    
    // Path to your Phi-3 model
    const char* model_path = "../phi3_official/cpu_and_mobile/cpu-int4-rtn-block-32-acc-level-4";
    
    try {
        std::cout << "📚 Loading model from: " << model_path << "\n";
        
        // Create model
        OgaModel* model = nullptr;
        if (OgaCreateModel(model_path, &model) != nullptr) {
            std::cerr << "❌ Failed to create model\n";
            return -1;
        }
        std::cout << "✅ Model loaded successfully\n";
        
        // Create tokenizer  
        OgaTokenizer* tokenizer = nullptr;
        if (OgaCreateTokenizer(model, &tokenizer) != nullptr) {
            std::cerr << "❌ Failed to create tokenizer\n";
            OgaDestroyModel(model);
            return -1;
        }
        std::cout << "✅ Tokenizer created successfully\n";
        
        // Create tokenizer stream
        OgaTokenizerStream* tokenizer_stream = nullptr;
        if (OgaCreateTokenizerStream(tokenizer, &tokenizer_stream) != nullptr) {
            std::cerr << "❌ Failed to create tokenizer stream\n";
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return -1;
        }
        std::cout << "✅ Tokenizer stream created successfully\n";
        
        std::cout << "\n💬 Interactive Chat Mode (type 'quit' or 'exit' to stop)\n";
        std::cout << "================================================\n";
        
        std::string user_input;
        while (true) {
            std::cout << "\n📥 Enter your question: ";
            std::getline(std::cin, user_input);
            
            // Check for exit commands
            if (user_input == "quit" || user_input == "exit" || user_input == "q") {
                std::cout << "👋 Goodbye!\n";
                break;
            }
            
            // Skip empty inputs
            if (user_input.empty()) {
                continue;
            }
            
            // Generate response
            if (generateResponse(user_input, model, tokenizer, tokenizer_stream) != 0) {
                std::cerr << "❌ Error generating response\n";
            }
        }
        
        // Cleanup
        OgaDestroyTokenizerStream(tokenizer_stream);
        OgaDestroyTokenizer(tokenizer);
        OgaDestroyModel(model);
        
        std::cout << "🎉 Interactive chat completed!\n";
        return 0;
        
    } catch (const std::exception& e) {
        std::cerr << "❌ Exception: " << e.what() << "\n";
        return -1;
    }
}
