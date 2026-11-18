// EXProcessInfo.h - Process data model

#import <Foundation/Foundation.h>

@interface EXProcessInfo : NSObject

@property (nonatomic, assign) pid_t pid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) uid_t uid;
@property (nonatomic, assign) BOOL isSuspended;
@property (nonatomic, assign) int cpuUsage;       // percentage * 10
@property (nonatomic, assign) uint64_t memoryUsage; // bytes

- (NSString *)formattedMemory;
- (NSString *)formattedCPU;
- (NSString *)ownerName;
- (BOOL)isSystemProcess;

@end
