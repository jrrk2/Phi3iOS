#include <iostream>
#include <string>
#include <vector>
#include <memory>

// Include the ONNX Runtime GenAI C API header
#include "ort_genai_c.h"

int test_phi3_main(const char *model_path) {
    std::cout << "🚀 Testing Phi-3 with ONNX Runtime GenAI C++ API on macOS\n";
    
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
        
        // Test input
        const char* user_input = "Hello, how are you?";
        std::cout << "📝 Testing with: '" << user_input << "'\n";
        
        // Format with Phi-3 chat template
        std::string chat_template = "<|user|>\n";
        chat_template += user_input;
        chat_template += " <|end|>\n<|assistant|>";
        
        std::cout << "🔤 Chat template: '" << chat_template << "'\n";
        
        // Encode the prompt
        OgaSequences* input_sequences = nullptr;
        if (OgaCreateSequences(&input_sequences) != nullptr) {
            std::cerr << "❌ Failed to create sequences\n";
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return -1;
        }
        
        if (OgaTokenizerEncode(tokenizer, chat_template.c_str(), input_sequences) != nullptr) {
            std::cerr << "❌ Failed to encode prompt\n";
            OgaDestroySequences(input_sequences);
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return -1;
        }
        
        size_t token_count = OgaSequencesGetSequenceCount(input_sequences, 0);
        std::cout << "🔢 Encoded " << token_count << " tokens\n";
        
        // Create generator parameters
        OgaGeneratorParams* params = nullptr;
        if (OgaCreateGeneratorParams(model, &params) != nullptr) {
            std::cerr << "❌ Failed to create generator params\n";
            OgaDestroySequences(input_sequences);
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return -1;
        }
        
        // Set generation parameters
        OgaGeneratorParamsSetSearchNumber(params, "max_length", 100.0);
        OgaGeneratorParamsSetSearchNumber(params, "batch_size", 1.0);
        
        // Create generator
        OgaGenerator* generator = nullptr;
        if (OgaCreateGenerator(model, params, &generator) != nullptr) {
            std::cerr << "❌ Failed to create generator\n";
            OgaDestroyGeneratorParams(params);
            OgaDestroySequences(input_sequences);
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return -1;
        }
        std::cout << "✅ Generator created successfully\n";
        
        // Append input tokens
        if (OgaGenerator_AppendTokenSequences(generator, input_sequences) != nullptr) {
            std::cerr << "❌ Failed to append tokens\n";
            OgaDestroyGenerator(generator);
            OgaDestroyGeneratorParams(params);
            OgaDestroySequences(input_sequences);
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return -1;
        }
        std::cout << "✅ Input tokens appended\n";
        
        // Generate response
        std::cout << "🤖 Generating response: ";
        std::string response;
        int token_count_generated = 0;
        const int max_tokens = 50;
        
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
                    response += token_text;
                    
                    // Check for end token
                    if (std::string(token_text).find("<|end|>") != std::string::npos) {
                        break;
                    }
                }
            }
            
            token_count_generated++;
        }
        
        std::cout << "\n✅ Generated " << token_count_generated << " tokens\n";
        std::cout << "📄 Full response: '" << response << "'\n";
        
        // Cleanup
        OgaDestroyGenerator(generator);
        OgaDestroyGeneratorParams(params);
        OgaDestroySequences(input_sequences);
        OgaDestroyTokenizerStream(tokenizer_stream);
        OgaDestroyTokenizer(tokenizer);
        OgaDestroyModel(model);
        
        std::cout << "🎉 C++ test completed successfully!\n";
        return 0;
        
    } catch (const std::exception& e) {
        std::cerr << "❌ Exception: " << e.what() << "\n";
        return -1;
    }
}
