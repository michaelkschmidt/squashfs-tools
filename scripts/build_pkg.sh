#!/bin/bash

#
# Build and package squashfs-tools
#
# Inputs:
#     SKIP_PACKAGE - set to "true" to skip the package making step
#     CROSS_COMPILE - if set to a gcc tuple, tries to crosscompile
#                     (e.g., x86_64-w64-mingw32)
#
# This script creates a static build of squashfs-tools to avoid dependency issues
# with libconfuse and libsodium. The result is a self-contained .deb
# and .rpm that should work on any Linux (assuming it's running on the
# same processor architecture) or an .exe for Windows.
#
# To build the Windows executable on Linux:
#  sudo apt-get install gcc-mingw-w64-x86-64
#  CROSS_COMPILE=x86_64-w64-mingw32 ./scripts/build_pkg.sh
#

set -e

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
BUILD_DIR=$BASE_DIR/build

MAKE_FLAGS=-j8
LDD=ldd

if [[ -z $CROSS_COMPILE ]]; then
   
    if [[ $(uname -s) = "Darwin" ]]; then
        SKIP_PACKAGE=true
        LDD="otool -L"
    fi
else
    CONFIGURE_ARGS=--host=$CROSS_COMPILE
fi


# Initial sanity checks
if [[ ! -e $BASE_DIR/squashfs-tools ]]; then
    echo "Please run from the squashfs-tools base directory"
    exit 1
fi

# Build the dependencies
. $BASE_DIR/scripts/download_deps.sh
SQUASHFS_INSTALL_DIR=$DEPS_DIR/staging/

# Initialize some directories
mkdir -p $BUILD_DIR
mkdir -p $SQUASHFS_INSTALL_DIR

pushd $BUILD_DIR

# Build squashfs-tools (symlink now, since out-of-tree squashfs-tools build is broke)
ln -sf $BASE_DIR/squashfs-tools $BUILD_DIR/
pushd squashfs-tools

export LIBRARY_PATH=$LIBRARY_PATH:$DEPS_INSTALL_DIR/lib
export EXTRA_CFLAGS="-Dlinux -DFNM_EXTMATCH=0 -D'sigtimedwait(a,b,c)=sigwaitinfo(a,b)' -I$LZMA_DIR/C -I$DEPS_INSTALL_DIR/include"
make clean
make $MAKE_FLAGS


# Run the regression tests
# make check

# make install-strip
# make dist
popd

# Return to the base directory
popd

# Package squashfs
if [[ "$SKIP_PACKAGE" != "true" ]]; then
    SQUASHFS_VERSION=$(cat VERSION)
    
    # Build Windows package
    mkdir -p $SQUASHFS_INSTALL_DIR/squashfs/tools/squashfs-tools
    cp scripts/squashfs.nuspec $SQUASHFS_INSTALL_DIR/squashfs/
    sed -i "s/%VERSION%/$(cat VERSION)/" $SQUASHFS_INSTALL_DIR/squashfs/squashfs.nuspec
    cp squashfs-tools/mksquashfs.exe $SQUASHFS_INSTALL_DIR/squashfs/tools/squashfs-tools
    cp squashfs-tools/unsquashfs.exe $SQUASHFS_INSTALL_DIR/squashfs/tools/squashfs-tools
    # TODO:  Generate this list from LDD
    cp /usr/bin/cygwin1.dll $SQUASHFS_INSTALL_DIR/squashfs/tools/squashfs-tools/
    cp /usr/bin/cygz.dll $SQUASHFS_INSTALL_DIR/squashfs/tools/squashfs-tools/
    cp /usr/bin/cyggcc_s-1.dll $SQUASHFS_INSTALL_DIR/squashfs/tools/squashfs-tools/
    
    pushd $SQUASHFS_INSTALL_DIR/squashfs/
    rm -f *.nupkg

    # TODO:  Run from CI
    # export ChocolateyInstall=$DEPS_INSTALL_DIR/chocolatey
    # $ChocolateyInstall/console/choco.exe pack --allow-unofficial squashfs.nuspec
    choco pack squashfs.nuspec
    popd

    rm -f *.nupkg
    cp $SQUASHFS_INSTALL_DIR/squashfs/*.nupkg .
fi


