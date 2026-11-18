// EXProcessManager.m - Process enumeration using sysctl/libproc

#import "EXProcessManager.h"
#import <sys/sysctl.h>
#import <sys/types.h>
#import <sys/param.h>
#import <signal.h>
#import <mach/mach.h>
#import <mach/task_info.h>
#import <libproc.h>
#import <pwd.h>

@implementation EXProcessManager

+ (instancetype)sharedManager {
    static EXProcessManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Process Enumeration

- (NSArray<EXProcessInfo *> *)allProcesses {
    NSMutableArray<EXProcessInfo *> *processes = [NSMutableArray array];
    
    // Get the process count
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t bufferSize = 0;
    
    if (sysctl(mib, 4, NULL, &bufferSize, NULL, 0) < 0) {
        NSLog(@"[Extrude] sysctl size query failed: %s", strerror(errno));
        return @[];
    }
    
    // Add extra buffer for new processes appearing between calls
    bufferSize += bufferSize / 8;
    
    struct kinfo_proc *procBuffer = (struct kinfo_proc *)malloc(bufferSize);
    if (!procBuffer) return @[];
    
    if (sysctl(mib, 4, procBuffer, &bufferSize, NULL, 0) < 0) {
        NSLog(@"[Extrude] sysctl proc query failed: %s", strerror(errno));
        free(procBuffer);
        return @[];
    }
    
    int procCount = (int)(bufferSize / sizeof(struct kinfo_proc));
    
    for (int i = 0; i < procCount; i++) {
        struct kinfo_proc *proc = &procBuffer[i];
        pid_t pid = proc->kp_proc.p_pid;
        
        if (pid == 0) continue; // Skip kernel_task pid 0
        
        EXProcessInfo *info = [[EXProcessInfo alloc] init];
        info.pid = pid;
        info.uid = proc->kp_eproc.e_ucred.cr_uid;
        info.isSuspended = (proc->kp_proc.p_stat == SSTOP);
        
        // Get process name
        char nameBuffer[PROC_PIDPATHINFO_MAXSIZE];
        memset(nameBuffer, 0, sizeof(nameBuffer));
        
        if (proc_name(pid, nameBuffer, sizeof(nameBuffer)) > 0) {
            info.name = [NSString stringWithUTF8String:nameBuffer];
        } else {
            info.name = [NSString stringWithUTF8String:proc->kp_proc.p_comm];
        }
        
        // Get process path
        char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
        memset(pathBuffer, 0, sizeof(pathBuffer));
        
        if (proc_pidpath(pid, pathBuffer, sizeof(pathBuffer)) > 0) {
            info.path = [NSString stringWithUTF8String:pathBuffer];
        } else {
            info.path = @"(unknown)";
        }
        
        // Get memory usage via mach task info
        info.memoryUsage = [self memoryUsageForPID:pid];
        
        // CPU usage (basic approximation via rusage)
        info.cpuUsage = [self cpuUsageForKProc:proc];
        
        [processes addObject:info];
    }
    
    free(procBuffer);
    
    return [processes copy];
}

- (uint64_t)memoryUsageForPID:(pid_t)pid {
    struct proc_taskinfo taskInfo;
    int ret = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, sizeof(taskInfo));
    if (ret == sizeof(taskInfo)) {
        return taskInfo.pti_resident_size;
    }
    return 0;
}

- (int)cpuUsageForKProc:(struct kinfo_proc *)proc {
    // Basic CPU usage estimation from process state
    // For more accurate readings, you'd need to sample over time
    if (proc->kp_proc.p_stat == SRUN) {
        return 10; // 1.0% placeholder for running processes
    }
    return 0;
}

- (NSArray<EXProcessInfo *> *)processesFilteredBy:(EXProcessFilter)filter
                                       searchText:(NSString *)searchText
                                        sortOrder:(EXSortOrder)sortOrder {
    
    NSArray<EXProcessInfo *> *all = [self allProcesses];
    NSMutableArray<EXProcessInfo *> *filtered = [NSMutableArray array];
    
    for (EXProcessInfo *proc in all) {
        // Apply filter
        switch (filter) {
            case EXProcessFilterAll:
                break;
            case EXProcessFilterUser:
                if (proc.isSystemProcess) continue;
                break;
            case EXProcessFilterSystem:
                if (!proc.isSystemProcess) continue;
                break;
            case EXProcessFilterApps:
                if (![proc.path containsString:@"/Applications/"] &&
                    ![proc.path containsString:@"/var/containers/"]) continue;
                break;
            case EXProcessFilterDaemons:
                if (![proc.path containsString:@"/usr/libexec/"] &&
                    ![proc.path containsString:@"/usr/sbin/"] &&
                    ![proc.name hasSuffix:@"d"]) continue;
                break;
        }
        
        // Apply search
        if (searchText.length > 0) {
            NSString *lowSearch = [searchText lowercaseString];
            BOOL matchesName = [[proc.name lowercaseString] containsString:lowSearch];
            BOOL matchesPID = [[NSString stringWithFormat:@"%d", proc.pid] containsString:searchText];
            BOOL matchesPath = [[proc.path lowercaseString] containsString:lowSearch];
            
            if (!matchesName && !matchesPID && !matchesPath) continue;
        }
        
        [filtered addObject:proc];
    }
    
    // Sort
    [filtered sortUsingComparator:^NSComparisonResult(EXProcessInfo *a, EXProcessInfo *b) {
        switch (sortOrder) {
            case EXSortOrderName:
                return [a.name caseInsensitiveCompare:b.name];
            case EXSortOrderPID:
                return a.pid < b.pid ? NSOrderedAscending : (a.pid > b.pid ? NSOrderedDescending : NSOrderedSame);
            case EXSortOrderMemory:
                return b.memoryUsage < a.memoryUsage ? NSOrderedAscending : (b.memoryUsage > a.memoryUsage ? NSOrderedDescending : NSOrderedSame);
            case EXSortOrderCPU:
                return b.cpuUsage < a.cpuUsage ? NSOrderedAscending : (b.cpuUsage > a.cpuUsage ? NSOrderedDescending : NSOrderedSame);
        }
        return NSOrderedSame;
    }];
    
    return [filtered copy];
}

#pragma mark - Process Control

- (BOOL)killProcessWithPID:(pid_t)pid {
    return [self sendSignal:SIGKILL toProcessWithPID:pid];
}

- (BOOL)suspendProcessWithPID:(pid_t)pid {
    return [self sendSignal:SIGSTOP toProcessWithPID:pid];
}

- (BOOL)resumeProcessWithPID:(pid_t)pid {
    return [self sendSignal:SIGCONT toProcessWithPID:pid];
}

- (BOOL)sendSignal:(int)signal toProcessWithPID:(pid_t)pid {
    int result = kill(pid, signal);
    if (result != 0) {
        NSLog(@"[Extrude] Failed to send signal %d to PID %d: %s", signal, pid, strerror(errno));
        return NO;
    }
    return YES;
}

#pragma mark - Detailed Info

- (NSString *)pathForPID:(pid_t)pid {
    char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
    memset(pathBuffer, 0, sizeof(pathBuffer));
    
    if (proc_pidpath(pid, pathBuffer, sizeof(pathBuffer)) > 0) {
        return [NSString stringWithUTF8String:pathBuffer];
    }
    return nil;
}

- (NSDictionary *)detailedInfoForPID:(pid_t)pid {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    // Basic proc info
    struct proc_bsdinfo bsdInfo;
    if (proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsdInfo, sizeof(bsdInfo)) == sizeof(bsdInfo)) {
        info[@"ppid"] = @(bsdInfo.pbi_ppid);
        info[@"pgid"] = @(bsdInfo.pbi_pgid);
        info[@"uid"] = @(bsdInfo.pbi_uid);
        info[@"gid"] = @(bsdInfo.pbi_gid);
        info[@"status"] = @(bsdInfo.pbi_status);
        info[@"flags"] = @(bsdInfo.pbi_flags);
        info[@"nice"] = @(bsdInfo.pbi_nice);
        info[@"start_time"] = @(bsdInfo.pbi_start_tvsec);
        
        if (bsdInfo.pbi_comm[0] != '\0') {
            info[@"comm"] = [NSString stringWithUTF8String:bsdInfo.pbi_comm];
        }
        if (bsdInfo.pbi_name[0] != '\0') {
            info[@"name"] = [NSString stringWithUTF8String:bsdInfo.pbi_name];
        }
    }
    
    // Task info (memory, threads)
    struct proc_taskinfo taskInfo;
    if (proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, sizeof(taskInfo)) == sizeof(taskInfo)) {
        info[@"virtual_size"] = @(taskInfo.pti_virtual_size);
        info[@"resident_size"] = @(taskInfo.pti_resident_size);
        info[@"total_user_time"] = @(taskInfo.pti_total_user);
        info[@"total_system_time"] = @(taskInfo.pti_total_system);
        info[@"threads_user"] = @(taskInfo.pti_threads_user);
        info[@"threads_system"] = @(taskInfo.pti_threads_system);
        info[@"policy"] = @(taskInfo.pti_policy);
        info[@"faults"] = @(taskInfo.pti_faults);
        info[@"pageins"] = @(taskInfo.pti_pageins);
        info[@"cow_faults"] = @(taskInfo.pti_cow_faults);
        info[@"messages_sent"] = @(taskInfo.pti_messages_sent);
        info[@"messages_received"] = @(taskInfo.pti_messages_received);
        info[@"syscalls_mach"] = @(taskInfo.pti_syscalls_mach);
        info[@"syscalls_unix"] = @(taskInfo.pti_syscalls_unix);
        info[@"csw"] = @(taskInfo.pti_csw);
        info[@"threadnum"] = @(taskInfo.pti_threadnum);
        info[@"numrunning"] = @(taskInfo.pti_numrunning);
        info[@"priority"] = @(taskInfo.pti_priority);
    }
    
    // Path
    NSString *path = [self pathForPID:pid];
    if (path) {
        info[@"path"] = path;
    }
    
    return [info copy];
}

@end
