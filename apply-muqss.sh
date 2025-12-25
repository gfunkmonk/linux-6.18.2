#!/bin/bash
# Script to apply MuQSS patch once it's available
# Usage: ./apply-muqss.sh <patch-file>

set -e

PATCH_FILE="${1:-0001-MultiQueue-Skiplist-Scheduler-v0.210.patch}"

echo "================================="
echo "MuQSS Patch Application Script"
echo "================================="
echo ""

# Check if patch file exists
if [ ! -f "$PATCH_FILE" ]; then
    echo "ERROR: Patch file not found: $PATCH_FILE"
    echo ""
    echo "Please download the patch first:"
    echo "  curl -O http://ck.kolivas.org/patches/muqss/5.0/5.12/0001-MultiQueue-Skiplist-Scheduler-v0.210.patch"
    echo ""
    echo "Or specify the patch file as an argument:"
    echo "  $0 /path/to/your/patch/file.patch"
    exit 1
fi

echo "Found patch file: $PATCH_FILE"
echo "File size: $(wc -c < "$PATCH_FILE") bytes"
echo ""

# Check if we're in the kernel source root
if [ ! -f "Makefile" ] || [ ! -d "kernel/sched" ]; then
    echo "ERROR: This script must be run from the Linux kernel source root directory"
    exit 1
fi

# Get kernel version
KERNEL_VERSION=$(grep "^VERSION = " Makefile | awk '{print $3}')
PATCHLEVEL=$(grep "^PATCHLEVEL = " Makefile | awk '{print $3}')
SUBLEVEL=$(grep "^SUBLEVEL = " Makefile | awk '{print $3}')

echo "Current kernel version: $KERNEL_VERSION.$PATCHLEVEL.$SUBLEVEL"
echo "Patch target version: 5.12"
echo ""
echo "⚠️  WARNING: This patch was designed for Linux 5.12"
echo "⚠️  You are applying it to Linux $KERNEL_VERSION.$PATCHLEVEL.$SUBLEVEL"
echo "⚠️  Conflicts and manual adjustments may be required"
echo ""

read -p "Do you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Applying patch..."
echo "================="
echo ""

# Try git apply first (cleaner)
if git apply --check "$PATCH_FILE" 2>/dev/null; then
    echo "✓ Patch can be applied cleanly with git apply"
    git apply "$PATCH_FILE"
    echo "✓ Patch applied successfully!"
elif git apply --3way --check "$PATCH_FILE" 2>/dev/null; then
    echo "⚠️  Patch has conflicts, trying 3-way merge..."
    git apply --3way "$PATCH_FILE"
    echo "✓ Patch applied with 3-way merge"
    echo "⚠️  Please review and resolve any conflicts"
else
    echo "⚠️  git apply failed, trying traditional patch command..."
    
    # Try with patch command
    if patch --dry-run -p1 < "$PATCH_FILE" > /dev/null 2>&1; then
        patch -p1 < "$PATCH_FILE"
        echo "✓ Patch applied successfully with patch command!"
    else
        echo "❌ ERROR: Unable to apply patch automatically"
        echo ""
        echo "The patch has significant conflicts. You may need to:"
        echo "1. Apply the patch manually: patch -p1 < $PATCH_FILE"
        echo "2. Resolve conflicts in the affected files"
        echo "3. Use a more recent version of the MuQSS patch for kernel $KERNEL_VERSION.$PATCHLEVEL"
        exit 1
    fi
fi

echo ""
echo "================================="
echo "Next Steps:"
echo "================================="
echo ""
echo "1. Review the changes:"
echo "   git status"
echo "   git diff"
echo ""
echo "2. Check for new scheduler files:"
echo "   ls -la kernel/sched/MuQSS*"
echo ""
echo "3. Configure the kernel to use MuQSS:"
echo "   make menuconfig"
echo "   # Go to: Processor type and features -> CPU scheduler"
echo "   # Select: MuQSS CPU scheduler"
echo ""
echo "4. Build the kernel:"
echo "   make -j\$(nproc)"
echo ""
echo "5. If there are build errors, check:"
echo "   - kernel/sched/MuQSS.c for any API changes needed"
echo "   - include/linux/sched.h for structure changes"
echo ""

exit 0
