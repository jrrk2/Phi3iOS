// GenAI.h - iOS Framework Header
#ifndef GENAI_H
#define GENAI_H

#ifdef __cplusplus
extern "C" {
#endif

// Basic GenAI functions for iOS
void* GenAI_CreateModel(const char* model_path);
void GenAI_DestroyModel(void* model);
char* GenAI_Generate(void* model, const char* prompt, int max_length);
void GenAI_FreeString(char* str);

#ifdef __cplusplus
}
#endif

#endif // GENAI_H
