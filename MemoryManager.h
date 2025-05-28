#import <Foundation/Foundation.h>

@interface MemoryManager : NSObject

+ (instancetype)shared;

// Memory pre-allocation
- (BOOL)preAllocateMemoryPool:(size_t)sizeInMB;
- (void)releaseMemoryPool;

// Emergency memory release
- (void)setupMemoryPressureHandling;
- (size_t)freeEmergencyMemory;

// Memory warming (touch pages to ensure they're resident)
- (void)warmUpAllocatedMemory;

// Model-specific memory management
- (BOOL)preAllocateForPHI3Model;
- (void)optimizeForInference;

// Memory monitoring
- (void)logMemoryStatus:(NSString *)context;
- (BOOL)hasEnoughMemoryForOperation:(size_t)requiredMB;

@end
