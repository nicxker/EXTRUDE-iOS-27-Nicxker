// EXProcessInfo.m

#import "EXProcessInfo.h"
#import <sys/types.h>
#import <pwd.h>

@implementation EXProcessInfo

- (NSString *)formattedMemory {
    if (self.memoryUsage == 0) return @"—";
    
    double bytes = (double)self.memoryUsage;
    if (bytes < 1024) {
        return [NSString stringWithFormat:@"%.0f B", bytes];
    } else if (bytes < 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f KB", bytes / 1024.0];
    } else if (bytes < 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f MB", bytes / (1024.0 * 1024.0)];
    } else {
        return [NSString stringWithFormat:@"%.2f GB", bytes / (1024.0 * 1024.0 * 1024.0)];
    }
}

- (NSString *)formattedCPU {
    if (self.cpuUsage <= 0) return @"0.0%";
    return [NSString stringWithFormat:@"%.1f%%", self.cpuUsage / 10.0];
}

- (NSString *)ownerName {
    struct passwd *pw = getpwuid(self.uid);
    if (pw && pw->pw_name) {
        return [NSString stringWithUTF8String:pw->pw_name];
    }
    return [NSString stringWithFormat:@"uid:%d", self.uid];
}

- (BOOL)isSystemProcess {
    // System processes typically run as root (0) or other low-uid system accounts
    return self.uid == 0 || self.uid < 500;
}

@end
