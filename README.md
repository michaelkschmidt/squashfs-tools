# SquashFS Tools for Windows

This is the source for the squashfs Chocolatey package.  It directly implements the Cygwin Port by Sebastiaan Ebeltjes:
http://domoticx.com/bestandssysteem-squashfs-tools-software/

# Building
From a Cygwin Shell, run
```
./scripts/build_pkg.sh
```

# Running
Install from Chocolatey
```
choco install squashfs
```

# TODO
- [x] Update version in squashfs.nuspec dynamicly
- [ ] Cross compile from Linux (Need for Travis CI)
