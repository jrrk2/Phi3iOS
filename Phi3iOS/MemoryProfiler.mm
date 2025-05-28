#import "MemoryProfiler.h"
#import <mach/mach.h>
#import <os/proc.h>
#import <sys/sysctl.h>

@interface MemoryProfiler ()
@property (nonatomic, strong) NSTimer *periodicTimer;
@property (nonatomic, assign) BOOL isMonitoring;
@property (nonatomic, strong) dispatch_source_t memoryPressureSource;
@end

@implementation MemoryProfiler

+ (instancetype)shared {
    static MemoryProfiler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MemoryProfiler alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isMonitoring = NO;
    }
    return self;
}

- (void)startProfiling {
    self.isMonitoring = YES;
    [self logCurrentMemoryUsage:@"📊 Memory profiling started"];
    [self startMemoryPressureMonitoring];
}

- (void)stopProfiling {
    self.isMonitoring = NO;
    [self disablePeriodicLogging];
    [self stopMemoryPressureMonitoring];
    [self logCurrentMemoryUsage:@"📊 Memory profiling stopped"];
}

- (void)logCurrentMemoryUsage:(NSString *)context {
    if (!self.isMonitoring) return;
    
    NSDictionary *stats = [self getCurrentMemoryStats];
    NSString *report = [self formatMemoryStats:stats withContext:context];
    NSLog(@"%@", report);
}

- (NSDictionary *)getCurrentMemoryStats {
    // Get task memory info
    task_vm_info_data_t taskInfo;
    mach_msg_type_number_t taskInfoCount = TASK_VM_INFO_COUNT;
    
    kern_return_t kr = task_info(mach_task_self(),
                                TASK_VM_INFO,
                                (task_info_t)&taskInfo,
                                &taskInfoCount);
    
    NSMutableDictionary *stats = [NSMutableDictionary dictionary];
    
    if (kr == KERN_SUCCESS) {
        // Memory usage in bytes
        stats[@"resident_size"] = @(taskInfo.phys_footprint);
        stats[@"virtual_size"] = @(taskInfo.virtual_size);
        stats[@"peak_resident"] = @(taskInfo.resident_size_peak);
        stats[@"compressed"] = @(taskInfo.compressed);
        
        // Memory usage in MB for readability
        stats[@"resident_mb"] = @(taskInfo.phys_footprint / (1024.0 * 1024.0));
        stats[@"virtual_mb"] = @(taskInfo.virtual_size / (1024.0 * 1024.0));
        stats[@"peak_mb"] = @(taskInfo.resident_size_peak / (1024.0 * 1024.0));
        stats[@"compressed_mb"] = @(taskInfo.compressed / (1024.0 * 1024.0));
    }
    
    // Get system memory info
    vm_size_t pageSize;
    host_page_size(mach_host_self(), &pageSize);
    
    vm_statistics64_data_t vmStats;
    mach_msg_type_number_t vmStatsCount = HOST_VM_INFO64_COUNT;
    
    kr = host_statistics64(mach_host_self(),
                          HOST_VM_INFO64,
                          (host_info64_t)&vmStats,
                          &vmStatsCount);
    
    if (kr == KERN_SUCCESS) {
        uint64_t totalPages = vmStats.free_count + vmStats.active_count + 
                             vmStats.inactive_count + vmStats.wire_count;
        
        stats[@"system_free_mb"] = @((vmStats.free_count * pageSize) / (1024.0 * 1024.0));
        stats[@"system_active_mb"] = @((vmStats.active_count * pageSize) / (1024.0 * 1024.0));
        stats[@"system_total_mb"] = @((totalPages * pageSize) / (1024.0 * 1024.0));
        stats[@"system_pressure"] = @(vmStats.compressions > 0 ? "HIGH" : "NORMAL");
    }
    
    // Get memory limit (if available)
    size_t memLimit = 0;
    size_t size = sizeof(memLimit);
    if (sysctlbyname("kern.memorystatus_memlimit_active", &memLimit, &size, NULL, 0) == 0) {
        stats[@"memory_limit_mb"] = @(memLimit);
    }
    
    return [stats copy];
}

- (NSString *)formatMemoryStats:(NSDictionary *)stats withContext:(NSString *)context {
    NSMutableString *report = [NSMutableString stringWithFormat:@"\n%@\n", context];
    [report appendString:@"════════════════════════════════════════\n"];
    
    // App memory usage
    [report appendFormat:@"📱 APP MEMORY:\n"];
    [report appendFormat:@"   Resident:     %.1f MB\n", [stats[@"resident_mb"] doubleValue]];
    [report appendFormat:@"   Virtual:      %.1f MB\n", [stats[@"virtual_mb"] doubleValue]];
    [report appendFormat:@"   Peak:         %.1f MB\n", [stats[@"peak_mb"] doubleValue]];
    [report appendFormat:@"   Compressed:   %.1f MB\n", [stats[@"compressed_mb"] doubleValue]];
    
    if (stats[@"memory_limit_mb"]) {
        double limit = [stats[@"memory_limit_mb"] doubleValue];
        double usage = [stats[@"resident_mb"] doubleValue];
        double percentage = (usage / limit) * 100.0;
        [report appendFormat:@"   Limit:        %.0f MB (%.1f%% used)\n", limit, percentage];
    }
    
    [report appendString:@"────────────────────────────────────────\n"];
    
    // System memory
    [report appendFormat:@"🖥️  SYSTEM MEMORY:\n"];
    [report appendFormat:@"   Free:         %.1f MB\n", [stats[@"system_free_mb"] doubleValue]];
    [report appendFormat:@"   Active:       %.1f MB\n", [stats[@"system_active_mb"] doubleValue]];
    [report appendFormat:@"   Total:        %.1f MB\n", [stats[@"system_total_mb"] doubleValue]];
    [report appendFormat:@"   Pressure:     %@\n", stats[@"system_pressure"]];
    
    [report appendString:@"════════════════════════════════════════"];
    
    return report;
}

- (NSString *)getFormattedMemoryReport {
    NSDictionary *stats = [self getCurrentMemoryStats];
    return [self formatMemoryStats:stats withContext:@"📊 Current Memory Status"];
}

- (void)enablePeriodicLogging:(NSTimeInterval)interval {
    [self disablePeriodicLogging]; // Stop any existing timer
    
    self.periodicTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                         repeats:YES
                                                           block:^(NSTimer *timer) {
        [self logCurrentMemoryUsage:@"📊 Periodic Memory Check"];
    }];
    
    NSLog(@"🔄 Enabled periodic memory logging every %.1f seconds", interval);
}

- (void)disablePeriodicLogging {
    if (self.periodicTimer) {
        [self.periodicTimer invalidate];
        self.periodicTimer = nil;
        NSLog(@"⏹️  Disabled periodic memory logging");
    }
}

- (void)startMemoryPressureMonitoring {
    if (self.memoryPressureSource) {
        [self stopMemoryPressureMonitoring];
    }
    
    self.memoryPressureSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_MEMORYPRESSURE,
                                                      0,
                                                      DISPATCH_MEMORYPRESSURE_NORMAL |
                                                      DISPATCH_MEMORYPRESSURE_WARN |
                                                      DISPATCH_MEMORYPRESSURE_CRITICAL,
                                                      dispatch_get_main_queue());
    
    if (self.memoryPressureSource) {
        dispatch_source_set_event_handler(self.memoryPressureSource, ^{
            unsigned long pressureLevel = dispatch_source_get_data(self.memoryPressureSource);
            NSString *levelString;
            
            if (pressureLevel & DISPATCH_MEMORYPRESSURE_CRITICAL) {
                levelString = @"🔴 CRITICAL";
            } else if (pressureLevel & DISPATCH_MEMORYPRESSURE_WARN) {
                levelString = @"🟡 WARNING";
            } else {
                levelString = @"🟢 NORMAL";
            }
            
            NSLog(@"⚠️  Memory pressure level changed: %@", levelString);
            [self logCurrentMemoryUsage:[NSString stringWithFormat:@"📊 Memory Pressure: %@", levelString]];
        });
        
        dispatch_resume(self.memoryPressureSource);
        NSLog(@"👁️  Started memory pressure monitoring");
    }
}

- (void)stopMemoryPressureMonitoring {
    if (self.memoryPressureSource) {
        dispatch_source_cancel(self.memoryPressureSource);
        self.memoryPressureSource = nil;
        NSLog(@"👁️  Stopped memory pressure monitoring");
    }
}

- (void)dealloc {
    [self stopProfiling];
}

@end
