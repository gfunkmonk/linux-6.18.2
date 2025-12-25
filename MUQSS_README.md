# Applying MuQSS Patch to Linux Kernel 6.18.2

This repository is being prepared to apply the MuQSS (Multiple Queue Skiplist Scheduler) v0.210 patch to the Linux 6.18.2 kernel.

## Current Status

⚠️ **BLOCKED**: The patch file cannot be automatically downloaded due to network restrictions.

**Action Required**: Please provide the patch file directly.

## Quick Start

### Step 1: Obtain the Patch File

Download the MuQSS v0.210 patch on your local machine:

```bash
curl -O http://ck.kolivas.org/patches/muqss/5.0/5.12/0001-MultiQueue-Skiplist-Scheduler-v0.210.patch
```

### Step 2: Add Patch to Repository

```bash
# Add the patch file to this repository
git add 0001-MultiQueue-Skiplist-Scheduler-v0.210.patch
git commit -m "Add MuQSS v0.210 patch file"
git push origin main
```

### Step 3: Apply the Patch

Once the patch file is in the repository, use the provided script:

```bash
# Make sure you're in the kernel source root
cd /home/runner/work/linux-6.18.2/linux-6.18.2

# Apply the patch
./apply-muqss.sh 0001-MultiQueue-Skiplist-Scheduler-v0.210.patch
```

## What is MuQSS?

The **Multiple Queue Skiplist Scheduler (MuQSS)** is a CPU scheduler designed by Con Kolivas. It aims to provide excellent desktop interactivity and responsiveness.

### Key Features:

- **Skiplist Data Structure**: Efficient O(log n) task management
- **Per-CPU Run Queues**: Minimizes lock contention
- **Low Latency**: Optimized for desktop and interactive workloads
- **Simple Logic**: Easier to understand and maintain than CFS
- **Tickless Design**: Works well with NO_HZ configurations

### How It Differs from CFS:

| Feature | CFS (Default) | MuQSS |
|---------|--------------|-------|
| Data Structure | Red-Black Tree | Skiplist |
| Complexity | Complex heuristics | Simpler logic |
| Primary Target | Server/General | Desktop/Interactive |
| Scheduling Granularity | Variable | Fixed timeslice |
| Load Balancing | Aggressive | Conservative |

## Patch Information

- **Version**: v0.210
- **Target Kernel**: Linux 5.12
- **Current Kernel**: Linux 6.18.2
- **Size**: ~290 KB
- **Files Modified**: 50+ files
- **Lines Changed**: ~10,000+

### Major Changes:

1. **New Files**:
   - `kernel/sched/MuQSS.c` (~8,000 lines) - Main scheduler implementation
   - `kernel/sched/MuQSS.h` (~600 lines) - Header definitions

2. **Modified Files**:
   - `kernel/sched/core.c` - Core scheduler hooks
   - `kernel/sched/Makefile` - Build configuration
   - `init/Kconfig` - Configuration options
   - `include/linux/sched.h` - Task structure changes
   - Many other files for integration

3. **Configuration**:
   - Adds `CONFIG_SCHED_MUQSS` option
   - Mutually exclusive with `CONFIG_SCHED_CFS`

## Known Issues

### Version Mismatch

The patch is designed for Linux 5.12, but we're applying it to 6.18.2. Expect:

- **API Changes**: Some kernel APIs may have changed between versions
- **Merge Conflicts**: File locations or functions may have moved
- **Structure Changes**: Task structures may have new/different fields
- **Build Errors**: May require manual fixes

### Typical Conflicts:

Common areas that may need manual resolution:

1. `kernel/sched/core.c` - Scheduler core changes
2. `include/linux/sched.h` - Task structure modifications
3. `kernel/sched/Makefile` - Build file updates
4. CPU architecture specific files (arch/x86, arch/arm64, etc.)

## Configuration

After applying the patch, configure the kernel:

```bash
# Interactive configuration
make menuconfig

# Navigate to:
# Processor type and features
#   -> CPU scheduler
#     -> [*] MuQSS CPU scheduler (NEW)

# Or use config commands:
scripts/config --enable CONFIG_SCHED_MUQSS
scripts/config --disable CONFIG_SCHED_CFS
```

### Recommended Additional Options:

```bash
# For best desktop performance
scripts/config --set-val CONFIG_HZ 1000
scripts/config --enable CONFIG_HZ_1000
scripts/config --enable CONFIG_PREEMPT
scripts/config --disable CONFIG_PREEMPT_VOLUNTARY
```

## Building

```bash
# Build the kernel
make -j$(nproc)

# Build kernel packages (Debian/Ubuntu)
make -j$(nproc) bindeb-pkg

# Build kernel packages (RPM-based)
make -j$(nproc) rpm-pkg
```

## Testing

After building and installing:

1. **Check Scheduler**:
   ```bash
   cat /proc/sys/kernel/sched_verbose
   dmesg | grep -i muqss
   ```

2. **Monitor Performance**:
   ```bash
   # Watch scheduling statistics
   watch -n1 cat /proc/schedstat
   
   # Check CPU usage
   htop
   ```

3. **Benchmark** (optional):
   ```bash
   # Compile time test
   time make clean && time make -j$(nproc)
   
   # Desktop responsiveness
   # Run video playback + heavy compilation simultaneously
   ```

## Troubleshooting

### Build Fails

If the build fails with errors in `kernel/sched/MuQSS.c`:

1. Check for API changes in newer kernel
2. Look for similar functions that replaced old ones
3. Consult kernel documentation: `Documentation/scheduler/`

### Conflicts During Patch

If there are merge conflicts:

```bash
# Manual merge
git apply --reject --whitespace=fix your-patch.patch

# Edit conflicted files (*.rej files show conflicts)
vim kernel/sched/core.c.rej

# Manually apply changes from .rej files
```

### Boot Fails

If the kernel doesn't boot:

1. Boot into previous kernel (GRUB menu)
2. Check kernel logs: `journalctl -k`
3. Try disabling MuQSS-specific features
4. Report issue with dmesg output

## Alternative Schedulers

If MuQSS doesn't work, consider these alternatives:

### BMQ (Bit Map Queue)
- Successor to PDS
- Available for newer kernels
- Simpler than MuQSS

### Project C
- Modern alternative by Alfred Chen
- Better kernel version support
- Active development

### cacULE
- CacULE scheduler
- Different approach to interactivity
- Good for gaming

## Resources

- **MuQSS Homepage**: http://ck.kolivas.org/
- **Documentation**: See `MUQSS_PATCH_STATUS.md`
- **Apply Script**: `./apply-muqss.sh`
- **Linux Scheduler Docs**: `Documentation/scheduler/`

## Support

For issues specific to this patch application:
1. Check `MUQSS_PATCH_STATUS.md` for detailed status
2. Review the PR description
3. Check dmesg and build logs
4. Comment on the PR with specific error messages

## License

The MuQSS scheduler and this kernel are licensed under GPL-2.0.
See `COPYING` for details.

---

**Note**: This is an experimental kernel modification. Test thoroughly before using in production.
