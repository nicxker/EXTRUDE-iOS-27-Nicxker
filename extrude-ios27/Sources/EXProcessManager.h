// EXProcessManager.h - Core process enumeration and management

#import <Foundation/Foundation.h>
#import "EXProcessInfo.h"

typedef NS_ENUM(NSInteger, EXSortOrder) {
    EXSortOrderName,
    EXSortOrderPID,
    EXSortOrderMemory,
    EXSortOrderCPU,
};

typedef NS_ENUM(NSInteger, EXProcessFilter) {
    EXProcessFilterAll,
    EXProcessFilterUser,
    EXProcessFilterSystem,
    EXProcessFilterApps,
    EXProcessFilterDaemons,
};

@interface EXProcessManager : NSObject

+ (instancetype)sharedManager;

// Process enumeration
- (NSArray<EXProcessInfo *> *)allProcesses;
- (NSArray<EXProcessInfo *> *)processesFilteredBy:(EXProcessFilter)filter
                                       searchText:(NSString *)searchText
                                        sortOrder:(EXSortOrder)sortOrder;

// Process control
- (BOOL)killProcessWithPID:(pid_t)pid;
- (BOOL)suspendProcessWithPID:(pid_t)pid;
- (BOOL)resumeProcessWithPID:(pid_t)pid;
- (BOOL)sendSignal:(int)signal toProcessWithPID:(pid_t)pid;

// Info
- (NSString *)pathForPID:(pid_t)pid;
- (NSDictionary *)detailedInfoForPID:(pid_t)pid;

@end
