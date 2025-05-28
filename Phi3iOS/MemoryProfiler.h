#import <Foundation/Foundation.h>

@interface MemoryProfiler : NSObject

// Memory usage tracking
+ (instancetype)shared;
- (void)startProfiling;
- (void)stopProfiling;
- (void)logCurrentMemoryUsage:(NSString *)context;

// Detailed memory breakdown
- (NSDictionary *)getCurrentMemoryStats;
- (NSString *)getFormattedMemoryReport;

// Automatic logging
- (void)enablePeriodicLogging:(NSTimeInterval)interval;
- (void)disablePeriodicLogging;

// Memory pressure monitoring
- (void)startMemoryPressureMonitoring;
- (void)stopMemoryPressureMonitoring;

@end
