#!/bin/bash

#
# Install dependencies on Travis
#
#

set -e
set -v

sudo apt-get update -qq
sudo apt-get install -qq autopoint mtools unzip

sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y gcc-mingw-w64-x86-64 wine

# These are needed for building choco
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb http://download.mono-project.com/repo/debian wheezy/snapshots/3.12.0 main" | sudo tee /etc/apt/sources.list.d/mono-xamarin.list
sudo apt-get update
sudo apt-get install -y mono-devel mono-gmcs nuget