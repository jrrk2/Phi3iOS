// test_phi3.cpp - Modified to accept input from stdin
#include <iostream>
#include <string>
#include <memory>
#include "ort_genai.h"

int main(int argc, char* argv[]) {
    std::cout << "🚀 Testing Phi-3 with ONNX Runtime GenAI C++ API on macOS" << std::endl;
    
    // Model path (can be overridden by command line argument)
    std::string model_path = "../phi3_official/cpu_and_mobile/cpu-int4-rtn-block-32-acc-level-4";
    if (argc > 1) {
        model_path = argv[1];
    }
    
    std::cout << "📚 Loading model from: " << model_path << std::endl;
    
    try {
        // Load the model
        auto model = Generators::CreateModel(OgaString{model_path.c_str()});
        std::cout << "✅ Model loaded successfully" << std::endl;
        
        // Create tokenizer
        auto tokenizer = model->CreateTokenizer();
        std::cout << "✅ Tokenizer created successfully" << std::endl;
        
        // Create tokenizer stream for chat template
        auto tokenizer_stream = Generators::CreateTokenizerStream(*tokenizer);
        std::cout << "✅ Tokenizer stream created successfully" << std::endl;
        
        // Get user input
        std::string user_input;
        std::cout << "\n💬 Enter your question (or press Enter for default): ";
        std::getline(std::cin, user_input);
        
        // Use default if input is empty
        if (user_input.empty()) {
            user_input = "Hello, how are you?";
            std::cout << "🔄 Using default question: '" << user_input << "'" << std::endl;
        }
        
        std::cout << "📝 Testing with: '" << user_input << "'" << std::endl;
        
        // Apply chat template
        std::string chat_template = "<|user|>\n" + user_input + " <|end|>\n<|assistant|>";
        std::cout << "🔤 Chat template: '" << chat_template << "'" << std::endl;
        
        // Encode the input
        auto sequences = tokenizer->Encode(chat_template.c_str());
        std::cout << "🔢 Encoded " << sequences->SequenceCount(0) << " tokens" << std::endl;
        
        // Create generator
        auto params = Generators::CreateGeneratorParams(*model);
        params->SetInputSequences(*sequences);
        params->TryGraphCaptureWithMaxBatchSize(1);
        
        auto generator = Generators::CreateGenerator(*model, *params);
        std::cout << "✅ Generator created successfully" << std::endl;
        
        // Generate response
        std::cout << "✅ Input tokens appended" << std::endl;
        std::cout << "🤖 Generating response: ";
        std::cout.flush();
        
        std::string response;
        while (!generator->IsDone()) {
            generator->GenerateNextToken();
            
            // Get the new token
            auto new_tokens = generator->GetSequence(0);
            auto new_token = (*new_tokens)[new_tokens->size() - 1];
            auto new_token_string = tokenizer_stream->Decode(new_token);
            
            std::cout << new_token_string;
            std::cout.flush();
            response += new_token_string;
        }
        
        std::cout << std::endl;
        std::cout << "✅ Generated " << (generator->GetSequence(0)->size() - sequences->SequenceCount(0)) << " tokens" << std::endl;
        std::cout << "📄 Full response: '" << response << "'" << std::endl;
        std::cout << "🎉 C++ test completed successfully!" << std::endl;
        
    } catch (const std::exception& e) {
        std::cerr << "❌ Error: " << e.what() << std::endl;
        return -1;
    }
    
    return 0;
}