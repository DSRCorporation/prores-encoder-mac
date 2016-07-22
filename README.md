# Description
PrEnc encodes and writes to QuickTime Movie file YUV 4:2:2 16-bit raw images with native OS X ProRes HQ codec using
VideoToolbox (VTCompressionSession) and AVFoundation (AVAssetWriter) frameworks.

# How to Build
Just run ```make``` in projedct root folder.
```
make RELEASE=1 # to make release build
```

Binary can be found in build/ directory.

NOTE: Only OS X build supported.

# Installation/Uninstallation
Run ```make install/uninstall``` to install/unintsall ```prenc``` binary.

Default path to install is /usr/local/bin. Maybe need to run installation command with ```sudo```.
