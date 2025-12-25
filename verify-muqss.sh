#!/bin/bash
# Verification script to check if MuQSS patch was applied correctly
# Usage: ./verify-muqss.sh

set -e

echo "======================================"
echo "MuQSS Patch Verification Script"
echo "======================================"
echo ""

ERRORS=0
WARNINGS=0

# Function to check if a file exists
check_file() {
    if [ -f "$1" ]; then
        echo "✓ Found: $1"
        return 0
    else
        echo "✗ Missing: $1"
        ((ERRORS++))
        return 1
    fi
}

# Function to check if a pattern exists in a file
check_pattern() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if [ ! -f "$file" ]; then
        echo "✗ File not found: $file"
        ((ERRORS++))
        return 1
    fi
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "✓ $description: $file"
        return 0
    else
        echo "✗ Missing $description in: $file"
        ((WARNINGS++))
        return 1
    fi
}

echo "Checking MuQSS core files..."
echo "------------------------------------"

# Check for new MuQSS files
check_file "kernel/sched/MuQSS.c"
check_file "kernel/sched/MuQSS.h"

echo ""
echo "Checking modified files..."
echo "------------------------------------"

# Check if Makefile was modified
check_pattern "kernel/sched/Makefile" "MuQSS" "MuQSS build rules"

# Check if Kconfig was modified
check_pattern "init/Kconfig" "SCHED_MUQSS\|MuQSS" "MuQSS config option"

# Check sched.h modifications
check_pattern "include/linux/sched.h" "muqss\|skiplist\|MUQSS" "MuQSS scheduler definitions"

echo ""
echo "Checking for potential issues..."
echo "------------------------------------"

# Check for reject files (indicates conflicts)
REJECT_FILES=$(find . -name "*.rej" 2>/dev/null)
if [ -n "$REJECT_FILES" ]; then
    echo "⚠️  WARNING: Found reject files (conflicts during patch):"
    echo "$REJECT_FILES"
    ((WARNINGS++))
else
    echo "✓ No reject files found"
fi

# Check for orig files (backup files from patch)
ORIG_FILES=$(find . -name "*.orig" 2>/dev/null | head -5)
if [ -n "$ORIG_FILES" ]; then
    echo "⚠️  INFO: Found backup files from patching:"
    echo "$ORIG_FILES" | head -5
    [ $(echo "$ORIG_FILES" | wc -l) -gt 5 ] && echo "   ... and more"
else
    echo "✓ No backup files found"
fi

echo ""
echo "Checking build configuration..."
echo "------------------------------------"

# Check if .config exists
if [ -f ".config" ]; then
    if grep -q "CONFIG_SCHED_MUQSS=y" .config 2>/dev/null; then
        echo "✓ CONFIG_SCHED_MUQSS is enabled in .config"
    elif grep -q "CONFIG_SCHED_MUQSS" .config 2>/dev/null; then
        echo "⚠️  CONFIG_SCHED_MUQSS found but not enabled"
        ((WARNINGS++))
    else
        echo "ℹ️  CONFIG_SCHED_MUQSS not in .config (run 'make menuconfig')"
    fi
    
    if grep -q "CONFIG_SCHED_CFS=y" .config 2>/dev/null; then
        echo "⚠️  WARNING: CONFIG_SCHED_CFS is still enabled (should be mutually exclusive)"
        ((WARNINGS++))
    fi
else
    echo "ℹ️  No .config file yet (run 'make menuconfig' or 'make defconfig')"
fi

echo ""
echo "Checking git status..."
echo "------------------------------------"

if git rev-parse --git-dir > /dev/null 2>&1; then
    MODIFIED=$(git status --porcelain | wc -l)
    if [ $MODIFIED -gt 0 ]; then
        echo "ℹ️  $MODIFIED files modified (expected after applying patch)"
        echo ""
        echo "   Modified files:"
        git status --short | head -10
        [ $(git status --porcelain | wc -l) -gt 10 ] && echo "   ... and more"
    else
        echo "⚠️  No modified files found (patch may not be applied yet)"
        ((WARNINGS++))
    fi
else
    echo "ℹ️  Not a git repository"
fi

echo ""
echo "======================================"
echo "Verification Summary"
echo "======================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✓ SUCCESS: MuQSS patch appears to be correctly applied!"
    echo ""
    echo "Next steps:"
    echo "1. Configure kernel: make menuconfig"
    echo "2. Enable CONFIG_SCHED_MUQSS"
    echo "3. Build kernel: make -j\$(nproc)"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  WARNINGS: $WARNINGS warning(s) found"
    echo ""
    echo "The patch appears to be applied, but there are some warnings."
    echo "Review the warnings above and address them if necessary."
    exit 0
else
    echo "✗ ERRORS: $ERRORS error(s) found"
    echo "⚠️  WARNINGS: $WARNINGS warning(s) found"
    echo ""
    echo "The patch does not appear to be correctly applied."
    echo "Please review the errors above and:"
    echo "1. Ensure the patch file was applied"
    echo "2. Check for and resolve any conflicts"
    echo "3. Verify all MuQSS files are present"
    exit 1
fi
