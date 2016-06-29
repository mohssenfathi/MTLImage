#!/usr/bin/env bash  
  
# Metal shaders are created in three steps:  
# - compile each .metal file into a single .air  
# - pack several .air files together into a single .metalar file  
# - build a Metal .metallib library file from the archive .metalar file  
#  
# https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Dev-Technique/Dev-Technique.html  
  
echo "Compiling metal shaders"
  
XCODE='/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform'  
METAL="$XCODE/usr/bin/metal"  
METAL_AR="$XCODE/usr/bin/metal-ar"  
METAL_LIB="$XCODE/usr/bin/metallib"  
SDK= "$XCODE/Developer/SDKs/iPhoneOS.sdk"

rm -f default.metal-ar default.metallib 
for x in *.air; do rm -f $x; done

for x in *.metal;
do $METAL -arch air64 -emit-llvm -c $SDK -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 $x -o ${x%.metal}.air;
done

for x in *.metal;
do $METAL_AR r default.metal-ar ${x%.metal}.air;
done

$METAL_LIB -o default.metallib default.metal-ar

rm -f default.metal-ar
for x in *.air;do rm -f $x; done
