#import "MemoryManager.h"
#import <mach/mach.h>
#import <sys/mman.h>
#import <pthread.h>
#import <sched.h>
#import <UIKit/UIKit.h>

@interface MemoryManager ()
@property (nonatomic, assign) void *memoryPool;
@property (nonatomic, assign) size_t poolSize;
@property (nonatomic, assign) void *emergencyBuffer;
@property (nonatomic, assign) size_t emergencySize;
@property (nonatomic, strong) dispatch_source_t memoryPressureSource;
@end

@implementation MemoryManager

+ (instancetype)shared {
    static MemoryManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MemoryManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _memoryPool = NULL;
        _poolSize = 0;
        _emergencyBuffer = NULL;
        _emergencySize = 20 * 1024 * 1024; // Smaller 20MB emergency buffer
        
        [self setupMemoryPressureHandling];
        [self allocateEmergencyBuffer];
    }
    return self;
}

- (BOOL)preAllocateMemoryPool:(size_t)sizeInMB {
    if (self.memoryPool) {
        [self releaseMemoryPool];
    }
    
    size_t bytes = sizeInMB * 1024 * 1024;
    
    NSLog(@"🧠 Pre-allocating %zu MB of memory...", sizeInMB);
    
    // Use mmap for better control over memory allocation
    self.memoryPool = mmap(NULL, bytes, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    
    if (self.memoryPool == MAP_FAILED) {
        NSLog(@"❌ Failed to allocate %zu MB memory pool", sizeInMB);
        self.memoryPool = NULL;
        return NO;
    }
    
    self.poolSize = bytes;
    
    // Try to lock pages in memory (may fail on iOS but worth trying)
    if (mlock(self.memoryPool, bytes) == 0) {
        NSLog(@"✅ Successfully locked %zu MB in physical memory", sizeInMB);
    } else {
        NSLog(@"⚠️ Could not lock memory pages (normal on iOS)");
    }
    
    // Touch all pages to ensure they're allocated
    [self warmUpAllocatedMemory];
    
    [self logMemoryStatus:@"After pre-allocation"];
    
    return YES;
}

- (void)warmUpAllocatedMemory {
    if (!self.memoryPool || self.poolSize == 0) return;
    
    NSLog(@"🔥 Warming up allocated memory pages...");
    
    // Touch every page to ensure it's resident
    size_t pageSize = getpagesize();
    volatile char *ptr = (volatile char *)self.memoryPool;
    
    for (size_t i = 0; i < self.poolSize; i += pageSize) {
        ptr[i] = 0; // Touch the page
    }
    
    NSLog(@"✅ Memory warm-up complete");
}

- (void)releaseMemoryPool {
    if (self.memoryPool && self.memoryPool != MAP_FAILED) {
        munmap(self.memoryPool, self.poolSize);
        self.memoryPool = NULL;
        self.poolSize = 0;
        NSLog(@"🗑️ Released pre-allocated memory pool");
    }
}

- (BOOL)preAllocateForPHI3Model {
    // Don't pre-allocate the full model size - let ONNX Runtime manage it
    // Just allocate a smaller emergency buffer and monitoring
    size_t bufferMemoryMB = 100;  // Much smaller - just 100MB buffer
    
    NSLog(@"🤖 Pre-allocating conservative memory buffer (%zu MB)", bufferMemoryMB);
    
    return [self preAllocateMemoryPool:bufferMemoryMB];
}

- (void)optimizeForInference {
    // Set thread priority for inference (simplified for iOS)
    [NSThread setThreadPriority:1.0]; // Max priority for current thread
    
    // iOS-specific optimizations
    if (@available(iOS 13.0, *)) {
        // iOS 13+ specific optimizations could go here
        // Most pthread scheduling is restricted on iOS
    }
    
    NSLog(@"⚡ Optimized system for inference");
}

- (void)allocateEmergencyBuffer {
    if (self.emergencyBuffer) return;
    
    self.emergencyBuffer = malloc(self.emergencySize);
    if (self.emergencyBuffer) {
        // Touch the emergency buffer to ensure it's resident
        memset(self.emergencyBuffer, 0, self.emergencySize);
        NSLog(@"🆘 Allocated %zu MB emergency buffer", self.emergencySize / (1024 * 1024));
    }
}

- (size_t)freeEmergencyMemory {
    if (self.emergencyBuffer) {
        free(self.emergencyBuffer);
        self.emergencyBuffer = NULL;
        
        size_t freedMB = self.emergencySize / (1024 * 1024);
        NSLog(@"🆘 Released %zu MB emergency memory", freedMB);
        return freedMB;
    }
    return 0;
}

- (void)setupMemoryPressureHandling {
    self.memoryPressureSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_MEMORYPRESSURE,
                                                      0,
                                                      DISPATCH_MEMORYPRESSURE_WARN | DISPATCH_MEMORYPRESSURE_CRITICAL,
                                                      dispatch_get_main_queue());
    
    if (self.memoryPressureSource) {
        __weak MemoryManager *weakSelf = self;
        dispatch_source_set_event_handler(self.memoryPressureSource, ^{
            unsigned long pressureLevel = dispatch_source_get_data(weakSelf.memoryPressureSource);
            
            if (pressureLevel & DISPATCH_MEMORYPRESSURE_CRITICAL) {
                NSLog(@"🚨 CRITICAL memory pressure - releasing emergency buffer");
                [weakSelf freeEmergencyMemory];
                
                // Post notification to app to reduce memory usage
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CriticalMemoryPressure" object:nil];
                
            } else if (pressureLevel & DISPATCH_MEMORYPRESSURE_WARN) {
                NSLog(@"⚠️ Memory pressure warning");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MemoryPressureWarning" object:nil];
            }
        });
        
        dispatch_resume(self.memoryPressureSource);
        NSLog(@"👁️ Memory pressure monitoring active");
    }
}

- (BOOL)hasEnoughMemoryForOperation:(size_t)requiredMB {
    // Get current memory stats
    task_vm_info_data_t taskInfo;
    mach_msg_type_number_t taskInfoCount = TASK_VM_INFO_COUNT;
    
    kern_return_t kr = task_info(mach_task_self(),
                                TASK_VM_INFO,
                                (task_info_t)&taskInfo,
                                &taskInfoCount);
    
    if (kr != KERN_SUCCESS) return YES; // Assume OK if we can't check
    
    // Get system memory info
    vm_size_t pageSize;
    host_page_size(mach_host_self(), &pageSize);
    
    vm_statistics64_data_t vmStats;
    mach_msg_type_number_t vmStatsCount = HOST_VM_INFO64_COUNT;
    
    kr = host_statistics64(mach_host_self(),
                          HOST_VM_INFO64,
                          (host_info64_t)&vmStats,
                          &vmStatsCount);
    
    if (kr != KERN_SUCCESS) return YES;
    
    size_t freeMemoryMB = (vmStats.free_count * pageSize) / (1024 * 1024);
    size_t currentUsageMB = taskInfo.phys_footprint / (1024 * 1024);
    
    // Check if we have enough free memory plus some buffer
    BOOL hasEnough = (freeMemoryMB > requiredMB + 200); // 200MB safety buffer
    
    NSLog(@"💾 Memory check: Need %zuMB, Free %zuMB, Current %zuMB - %@",
          requiredMB, freeMemoryMB, currentUsageMB, hasEnough ? @"✅ OK" : @"❌ LOW");
    
    return hasEnough;
}

- (void)logMemoryStatus:(NSString *)context {
    task_vm_info_data_t taskInfo;
    mach_msg_type_number_t taskInfoCount = TASK_VM_INFO_COUNT;
    
    kern_return_t kr = task_info(mach_task_self(),
                                TASK_VM_INFO,
                                (task_info_t)&taskInfo,
                                &taskInfoCount);
    
    if (kr == KERN_SUCCESS) {
        size_t residentMB = taskInfo.phys_footprint / (1024 * 1024);
        size_t peakMB = taskInfo.resident_size_peak / (1024 * 1024);
        size_t poolMB = self.poolSize / (1024 * 1024);
        
        NSLog(@"🧠 %@ - Resident: %zuMB, Peak: %zuMB, Pool: %zuMB",
              context, residentMB, peakMB, poolMB);
    }
}

- (void)dealloc {
    [self releaseMemoryPool];
    [self freeEmergencyMemory];
    
    if (self.memoryPressureSource) {
        dispatch_source_cancel(self.memoryPressureSource);
    }
}

@end
