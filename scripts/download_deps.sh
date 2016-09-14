#!/bin/bash

#
# Download and build dependencies as static libs
#
# Inputs:
#     CROSS_COMPILE - if set to a gcc tuple, tries to crosscompile
#                     (e.g., x86_64-w64-mingw32)
#
set -e

LZ4_VERSION=r130
LZMA_VERSION=4.65
LZO_VERSION=2.09
XZ_VERSION=5.2.2
CHOCO_VERSION=0.10.0

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
BUILD_DIR=$BASE_DIR/build
DOWNLOAD_DIR=$BUILD_DIR/dl

if [[ -z $CROSS_COMPILE ]]; then
    DEPS_DIR=$BUILD_DIR/host/deps
else
    DEPS_DIR=$BUILD_DIR/$CROSS_COMPILE/deps
    CONFIGURE_ARGS=--host=$CROSS_COMPILE
    _CONFIGURE_ENV="CC=$CROSS_COMPILE-gcc"
fi

export LZO_DIR=$DEPS_DIR/lzo-$LZO_VERSION
export LZMA_DIR=$DEPS_DIR/lzma-$LZMA_VERSION

DEPS_INSTALL_DIR=$DEPS_DIR/usr
PKG_CONFIG_PATH=$DEPS_INSTALL_DIR/lib/pkgconfig

MAKE_FLAGS=-j8

# Initialize some directories
mkdir -p $DOWNLOAD_DIR
mkdir -p $DEPS_INSTALL_DIR

pushd $DEPS_DIR

pushd $DOWNLOAD_DIR
[[ -e xz-$XZ_VERSION.tar.xz ]] || wget http://tukaani.org/xz/xz-$XZ_VERSION.tar.xz
[[ -e lz4-$LZ4_VERSION.tar.gz ]] || wget -O lz4-$LZ4_VERSION.tar.gz https://github.com/Cyan4973/lz4/archive/$LZ4_VERSION.tar.gz
[[ -e lzma-$LZMA_VERSION.tar.bz2 ]] || wget -O lzma-$LZMA_VERSION.tar.bz2 "http://downloads.sourceforge.net/project/sevenzip/LZMA%20SDK/4.65/lzma465.tar.bz2?r=&ts=1473858516&use_mirror=heanet"
[[ -e lzo-$LZO_VERSION.tar.gz ]] || wget http://www.oberhumer.com/opensource/lzo/download/lzo-$LZO_VERSION.tar.gz
#[[ -e choco-$CHOCO_VERSION.tar.gz ]] || wget -O choco-$CHOCO_VERSION.tar.gz https://github.com/chocolatey/choco/archive/$CHOCO_VERSION.tar.gz
popd

# Build XZ
if [[ ! -e $DEPS_INSTALL_DIR/bin/xz.exe ]]; then
    rm -fr xz-*
    tar xf $DOWNLOAD_DIR/xz-$XZ_VERSION.tar.xz
    pushd xz-$XZ_VERSION
    PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure $CONFIGURE_ARGS --prefix=$DEPS_INSTALL_DIR --enable-shared=no
    make $MAKE_FLAGS
    make install
    popd
fi

# Build LZ4
if [[ ! -e $DEPS_INSTALL_DIR/lib/liblz4.a ]]; then
    rm -fr lz4-*
    tar xf $DOWNLOAD_DIR/lz4-$LZ4_VERSION.tar.gz
    pushd lz4-$LZ4_VERSION   
    
    cp -f $BASE_DIR/patches/lz4_Makefile ./Makefile
    cp -f $BASE_DIR/patches/lz4_lib_Makefile ./lib/Makefile
    export $_CONFIGURE_ENV; 
    export PREFIX=$DEPS_INSTALL_DIR 
    make $MAKE_FLAGS
    make install
    unset PREFIX
    popd
fi

# Unpack LZMA
if [[ ! -e $LZMA_DIR ]]; then
    rm -fr lzma-*
    mkdir -p lzma-$LZMA_VERSION
    pushd lzma-$LZMA_VERSION
    tar xf $DOWNLOAD_DIR/lzma-$LZMA_VERSION.tar.bz2
    popd
fi

# Build LZO
if [[ ! -e $DEPS_INSTALL_DIR/lib/liblzo2.a ]]; then
    rm -fr lzo-*
    tar xf $DOWNLOAD_DIR/lzo-$LZO_VERSION.tar.gz
    pushd lzo-$LZO_VERSION
    PKG_CONFIG_PATH=$PKG_CONFIG_PATH LDFLAGS=-L$DEPS_INSTALL_DIR/lib CPPFLAGS=-I$DEPS_INSTALL_DIR/include ./configure \
        $CONFIGURE_ARGS \
        --prefix=$DEPS_INSTALL_DIR \
        --enable-shared=no
    make $MAKE_FLAGS
    make install
    popd
fi

# # Chocolatey
# if [[ ! -e $DEPS_INSTALL_DIR/chocolatey ]]; then
#     rm -fr choco-*
#     tar xf $DOWNLOAD_DIR/choco-$CHOCO_VERSION.tar.gz
#     pushd choco-$CHOCO_VERSION
#     nuget restore src/chocolatey.sln
#     chmod +x build.sh
#     ./build.sh -v
#     cp -Rf code_drop/chocolatey $DEPS_INSTALL_DIR/
#     popd
# fi

# Return to the base directory
popd

echo Dependencies built successfully!
echo
echo To compile statically with these libraries, run:
echo
echo "./autogen.sh # if you're compiling from source"
echo PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure $CONFIGURE_ARGS --enable-shared=no
echo make
echo make check
echo make install
