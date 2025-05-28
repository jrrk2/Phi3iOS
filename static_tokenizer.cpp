// static_tokenizer.cpp - Simplified tokenizer for iOS

#include <string>
#include <vector>
#include <sstream>
#include <iostream>

// Simple static tokenizer that doesn't rely on external libraries
class StaticTokenizer {
private:
    static std::vector<std::string> SplitString(const std::string& text, char delimiter = ' ') {
        std::vector<std::string> tokens;
        std::stringstream ss(text);
        std::string token;
        
        while (std::getline(ss, token, delimiter)) {
            if (!token.empty()) {
                tokens.push_back(token);
            }
        }
        return tokens;
    }
    
public:
    static std::vector<int32_t> SimpleTokenize(const std::string& text) {
        auto words = SplitString(text);
        std::vector<int32_t> tokens;
        
        // Simple word-to-ID mapping (just use word length as a proxy)
        for (const auto& word : words) {
            tokens.push_back(static_cast<int32_t>(word.length()));
        }
        
        return tokens;
    }
    
    static std::string SimpleDetokenize(const std::vector<int32_t>& tokens) {
        std::string result;
        for (size_t i = 0; i < tokens.size(); ++i) {
            if (i > 0) result += " ";
            result += "token_" + std::to_string(tokens[i]);
        }
        return result;
    }
};

// C API for static tokenizer
extern "C" {
    void* StaticCreateTokenizer(const char* config_path) {
        std::cout << "Created static tokenizer (iOS build)" << std::endl;
        return new StaticTokenizer();
    }
    
    void StaticDestroyTokenizer(void* tokenizer) {
        delete static_cast<StaticTokenizer*>(tokenizer);
    }
}
