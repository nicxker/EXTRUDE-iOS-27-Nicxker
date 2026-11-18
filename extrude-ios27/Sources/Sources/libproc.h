// libproc.h - Self-contained process information declarations for iOS
#ifndef _LIBPROC_H_
#define _LIBPROC_H_

#include <sys/types.h>
#include <stdint.h>

#define PROC_PIDPATHINFO_MAXSIZE 4096
#define PROC_PIDTASKINFO 4
#define PROC_PIDTBSDINFO 3

#ifndef MAXCOMLEN
#define MAXCOMLEN 16
#endif

struct proc_taskinfo {
    uint64_t                pti_virtual_size;
    uint64_t                pti_resident_size;
    uint64_t                pti_total_user;
    uint64_t                pti_total_system;
    uint64_t                pti_threads_user;
    uint64_t                pti_threads_system;
    int32_t                 pti_policy;
    int32_t                 pti_faults;
    int32_t                 pti_pageins;
    int32_t                 pti_cow_faults;
    int32_t                 pti_messages_sent;
    int32_t                 pti_messages_received;
    int32_t                 pti_syscalls_mach;
    int32_t                 pti_syscalls_unix;
    int32_t                 pti_csw;
    int32_t                 pti_threadnum;
    int32_t                 pti_numrunning;
    int32_t                 pti_priority;
};

struct proc_bsdinfo {
    uint32_t                pbi_flags;
    uint32_t                pbi_status;
    uint32_t                pbi_xstatus;
    uint32_t                pbi_pid;
    uint32_t                pbi_ppid;
    uid_t                   pbi_uid;
    gid_t                   pbi_gid;
    uid_t                   pbi_ruid;
    gid_t                   pbi_rgid;
    uid_t                   pbi_svuid;
    gid_t                   pbi_svgid;
    uint32_t                rfu_1;
    char                    pbi_comm[MAXCOMLEN];
    char                    pbi_name[2 * MAXCOMLEN];
    uint32_t                pbi_nfiles;
    uint32_t                pbi_pgid;
    uint32_t                pbi_pjobc;
    uint32_t                rfu_2;
    uint32_t                pbi_nice;
    uint64_t                pbi_start_tvsec;
    uint64_t                pbi_start_tvusec;
};

#ifdef __cplusplus
extern "C" {
#endif

int proc_name(int pid, void *buffer, uint32_t buffersize);
int proc_pidpath(int pid, void *buffer, uint32_t buffersize);
int proc_pidinfo(int pid, int flavor, uint64_t arg, void *buffer, int buffersize);

#ifdef __cplusplus
}
#endif

#endif /* _LIBPROC_H_ */
