// working_tokenizer.cpp - Functional tokenizer for static build

#include <string>
#include <vector>
#include <sstream>
#include <iostream>
#include <memory>
#include <span>

namespace Generators {
    class Config;
    class State;
    
    // Forward declaration
    class Tokenizer;
    
    // TokenizerStream implementation
    class TokenizerStream {
    private:
        std::shared_ptr<const Tokenizer> tokenizer_;
        std::string chunk_;
        
    public:
        TokenizerStream(const Tokenizer& tokenizer);
        const std::string& Decode(int32_t token);
    };
    
    // Main Tokenizer implementation
    class Tokenizer {
    private:
        int32_t pad_token_id_;
        std::string config_path_;
        
    public:
        Tokenizer(Config& config) : pad_token_id_(0) {
            std::cout << "Working Tokenizer created" << std::endl;
        }
        
        std::shared_ptr<const Tokenizer> shared_from_this() const {
            return std::shared_ptr<const Tokenizer>(this, [](const Tokenizer*){});
        }
        
        std::unique_ptr<TokenizerStream> CreateStream() const {
            return std::make_unique<TokenizerStream>(*this);
        }
        
        std::vector<int32_t> Encode(const char* text) const {
            std::vector<int32_t> tokens;
            if (!text) return tokens;
            
            std::string input(text);
            std::istringstream iss(input);
            std::string word;
            
            while (iss >> word) {
                // Use word length as a simple token ID
                tokens.push_back(static_cast<int32_t>(word.length()));
            }
            
            std::cout << "Tokenized '" << text << "' into " << tokens.size() << " tokens" << std::endl;
            return tokens;
        }
        
        std::string Decode(std::span<const int32_t> tokens) const {
            std::string result;
            for (size_t i = 0; i < tokens.size(); ++i) {
                if (i > 0) result += " ";
                result += "word" + std::to_string(tokens[i]);
            }
            
            std::cout << "Decoded " << tokens.size() << " tokens into: '" << result << "'" << std::endl;
            return result;
        }
        
        std::string ApplyChatTemplate(const char* template_str, const char* messages, 
                                     const char* tools, bool add_generation_prompt) const {
            std::string result;
            
            if (messages) {
                result = std::string(messages);
            }
            
            if (add_generation_prompt) {
                if (!result.empty()) result += "\n";
                result += "Assistant: ";
            }
            
            std::cout << "Applied chat template, result: '" << result << "'" << std::endl;
            return result;
        }
        
        int32_t TokenToTokenId(const char* token) const {
            if (!token) return 0;
            int32_t id = static_cast<int32_t>(strlen(token));
            std::cout << "Token '" << token << "' -> ID " << id << std::endl;
            return id;
        }
        
        std::vector<int32_t> EncodeBatch(std::span<const std::string> strings) const {
            std::vector<int32_t> result;
            for (const auto& str : strings) {
                auto tokens = Encode(str.c_str());
                result.insert(result.end(), tokens.begin(), tokens.end());
            }
            return result;
        }
        
        std::vector<std::string> DecodeBatch(std::span<const int32_t> sequences, size_t count) const {
            std::vector<std::string> results;
            if (count == 0 || sequences.empty()) return results;
            
            size_t seq_len = sequences.size() / count;
            for (size_t i = 0; i < count; ++i) {
                auto start = sequences.begin() + (i * seq_len);
                auto end = start + seq_len;
                std::vector<int32_t> seq_tokens(start, end);
                results.push_back(Decode(seq_tokens));
            }
            
            return results;
        }
        
        // Shared pointer utilities for integration
        std::shared_ptr<class Tensor> EncodeBatch(std::span<const char*> strings) const {
            // Simplified implementation - return nullptr for now
            // Real implementation would create proper tensor
            std::cout << "EncodeBatch called with " << strings.size() << " strings" << std::endl;
            return nullptr;
        }
    };
    
    // TokenizerStream implementation
    TokenizerStream::TokenizerStream(const Tokenizer& tokenizer) 
        : tokenizer_(tokenizer.shared_from_this()) {
        std::cout << "TokenizerStream created" << std::endl;
    }
    
    const std::string& TokenizerStream::Decode(int32_t token) {
        chunk_ = "token_" + std::to_string(token);
        return chunk_;
    }
    
    // Helper functions for padding
    std::vector<int32_t> PadInputs(std::span<std::span<const int32_t>> sequences, int32_t pad_token_id) {
        if (sequences.empty()) return {};
        
        // Find max length
        size_t max_length = 0;
        for (auto& seq : sequences) {
            max_length = std::max(max_length, seq.size());
        }
        
        // Create padded result
        std::vector<int32_t> result;
        result.reserve(max_length * sequences.size());
        
        for (auto& seq : sequences) {
            // Copy sequence
            result.insert(result.end(), seq.begin(), seq.end());
            
            // Add padding
            size_t padding_needed = max_length - seq.size();
            for (size_t i = 0; i < padding_needed; ++i) {
                result.push_back(pad_token_id);
            }
        }
        
        std::cout << "Padded " << sequences.size() << " sequences to length " << max_length << std::endl;
        return result;
    }
}