# CacULE Scheduler Patch - Refactored for Linux 6.18.2

## Overview

This patch has been refactored to apply cleanly to Linux kernel 6.18.2. The original patch (dated December 2022) was designed for Linux kernel ~5.19/6.0 and did not apply to 6.18.2 due to significant scheduler changes, particularly the introduction of the EEVDF (Earliest Eligible Virtual Deadline First) scheduler in Linux 6.6+.

## What Has Been Applied

This refactored patch includes the **foundational structures and configuration** for the CacULE scheduler:

### ✅ Completed Changes

1. **Data Structures** (`include/linux/sched.h`)
   - Added `struct cacule_node` definition
   - Added `cacule_node` field to `struct sched_entity`
   - Adapted to new sched_entity structure (deadline, min_vruntime, min_slice fields)

2. **System Configuration** (`include/linux/sched/sysctl.h`)
   - Added CacULE sysctl variable declarations
   - interactivity_factor, cacule_max_lifetime, cache_factor, etc.

3. **Topology** (`include/linux/sched/topology.h`)
   - Removed `nr_idle_scan` field (part of CacULE changes)

4. **Kernel Configuration** (`init/Kconfig`, `kernel/Kconfig.hz`)
   - Added CONFIG_CACULE_SCHED option
   - Added CONFIG_CACULE_RDB (Response Driven Balancer) option
   - Added CONFIG_RDB_INTERVAL configuration
   - Added HZ_2000 option for high-frequency scheduling
   - Set SCHED_AUTOGROUP default to y

5. **Documentation**
   - Created `Documentation/scheduler/sched-CacULE.rst` with CacULE overview
   - Added sysctl documentation for `sched_interactivity_factor`

## What Still Needs to Be Done

The following files require **manual porting** due to fundamental scheduler changes in Linux 6.6-6.18:

### ⚠️ Pending Changes (Requires Expert Knowledge)

1. **Core Scheduler** (`kernel/sched/core.c`)
   - Initialize cacule_node fields in `__sched_fork()`
   - Set `cacule_start_time` in `wake_up_new_task()`
   - Adapt to new `update_rq_clock_pelt()` API (replaced `update_rq_clock_task_mult()`)
   - Handle `sched_tick_remote()` changes
   - Add CacULE scheduler initialization message

2. **Fair Scheduler** (`kernel/sched/fair.c`)
   - Implement CacULE's interactivity scoring algorithms
   - Replace RB-tree operations with linked list for CacULE
   - Implement `pick_next_entity()` based on interactivity scores
   - Add RDB (Response Driven Balancer) load balancing logic
   - Adapt `enqueue_entity()` and `dequeue_entity()` for CacULE
   - Implement cache and starvation scoring
   - Handle EEVDF-specific fields (deadline, min_slice)

3. **PELT (Per-Entity Load Tracking)** (`kernel/sched/pelt.c`, `kernel/sched/pelt.h`)
   - Adapt to new PELT implementation
   - Remove deprecated `update_rq_clock_task_mult()` references
   - Update `update_rq_clock_pelt()` integration

4. **Scheduler Headers** (`kernel/sched/sched.h`)
   - Add CacULE-specific rq fields (max_IS_score, to_migrate_task)
   - Adapt cfs_rq structure for CacULE head pointer
   - Handle changes to min_vruntime tracking

5. **Debug Interface** (`kernel/sched/debug.c`)
   - Update debug output for CacULE statistics
   - Handle min_vruntime conditional compilation

6. **Scheduler Features** (`kernel/sched/features.h`)
   - Update SIS_PROP/SIS_UTIL feature flags

7. **Sysctl Interface** (`kernel/sysctl.c`)
   - Add CacULE sysctl handlers
   - Register interactivity_factor, cacule_max_lifetime, etc.

## Why This Is Complex

The Linux scheduler underwent a major redesign between 6.0 and 6.6:

- **EEVDF Integration**: The CFS scheduler was enhanced with EEVDF algorithm, changing core data structures
- **New sched_entity Fields**: Added `deadline`, `min_vruntime`, `min_slice` fields
- **PELT Refactoring**: Load tracking implementation was significantly refactored
- **Function Renames**: Many core scheduler functions were renamed or restructured

CacULE was designed for the pre-EEVDF scheduler and needs careful adaptation to work with these changes.

## How to Complete the Port

To fully port CacULE to Linux 6.18.2:

1. **Study EEVDF Changes**
   - Understand how deadline, min_vruntime, and min_slice work in EEVDF
   - Review commits that introduced EEVDF (Linux 6.6 merge window)

2. **Adapt CacULE Logic**
   - Modify interactivity scoring to work with EEVDF's deadline-based scheduling
   - Ensure CacULE's linked list doesn't conflict with EEVDF's RB-tree usage
   - Handle the new scheduling entity states (sched_delayed, rel_deadline, etc.)

3. **Test Thoroughly**
   - Verify scheduling correctness under various workloads
   - Test RDB load balancer with modern SMP architectures
   - Ensure no regressions in standard scheduler paths

## Testing Current Patch

To verify the refactored patch applies cleanly:

```bash
cd /path/to/linux-6.18.2
patch -p1 --dry-run < 0001-cacULE-cachy.patch
```

To apply:

```bash
patch -p1 < 0001-cacULE-cachy.patch
```

## Original Patch Information

- **Author**: Peter Jung <admin@ptr1337.dev>
- **Date**: Mon, 12 Dec 2022
- **Original CacULE Author**: Hamad Al Marri
- **Target Kernel**: Linux ~5.19/6.0
- **Refactored For**: Linux 6.18.2

## References

- ULE Scheduler Paper: https://web.cs.ucdavis.edu/~roper/ecs150/ULE.pdf
- CachyOS Project: https://github.com/CachyOS
- Linux EEVDF Scheduler: https://lwn.net/Articles/925371/

## Notes

This refactored patch provides the **foundation** for CacULE but does NOT implement the full scheduler. The kernel will compile with this patch applied (with CONFIG_CACULE_SCHED disabled), but enabling CacULE will require completing the pending changes listed above.

For production use, seek an expert in Linux scheduler development or wait for an official CacULE port to Linux 6.6+.
