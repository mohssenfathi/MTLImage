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

rm default.metal-ar default.metallib shaders.air Blend.air Brightness.air Camera.air Contrast.air \
Convolution.air CrossHatch.air DefaultShaders.air Distortion.air Exposure.air GaussianBlur.air Haze.air Invert.air Kuwahara.air \
Levels.air Mask.air OilPaint.air PerlinNoise.air Pixellate.air PolkaDot.air Saturation.air SelectiveHSL.air Sharpen.air Sketch.air \
SobelEdgeDetection.air Toon.air Vignette.air Water.air Watercolor.air WhiteBalance.air

"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Blend.metal -o Blend.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Brightness.metal -o Brightness.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Camera.metal -o Camera.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Contrast.metal -o Contrast.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Convolution.metal -o Convolution.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 CrossHatch.metal -o CrossHatch.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 DefaultShaders.metal -o  DefaultShaders.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Distortion.metal -o Distortion.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Exposure.metal -o Exposure.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 GaussianBlur.metal -o GaussianBlur.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Haze.metal -o Haze.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Invert.metal -o Invert.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Kuwahara.metal -o Kuwahara.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Levels.metal -o Levels.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Mask.metal -o Mask.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 OilPaint.metal -o OilPaint.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 PerlinNoise.metal -o PerlinNoise.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 SelectiveHSL.metal -o SelectiveHSL.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Pixellate.metal -o Pixellate.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 PolkaDot.metal -o PolkaDot.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Saturation.metal -o Saturation.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Sharpen.metal -o Sharpen.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Sketch.metal -o Sketch.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 SobelEdgeDetection.metal -o SobelEdgeDetection.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Toon.metal -o Toon.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Vignette.metal -o Vignette.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Water.metal -o Water.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 Watercolor.metal -o Watercolor.air
"$METAL" -arch air64 -emit-llvm -c "$SDK" -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 WhiteBalance.metal -o WhiteBalance.air

"$METAL_AR" r default.metal-ar Blend.air Brightness.air Camera.air Contrast.air \
Convolution.air CrossHatch.air DefaultShaders.air Distortion.air Exposure.air GaussianBlur.air Haze.air Invert.air Kuwahara.air \
Levels.air Mask.air OilPaint.air PerlinNoise.air Pixellate.air PolkaDot.air Saturation.air SelectiveHSL.air Sharpen.air Sketch.air SobelEdgeDetection.air Toon.air Vignette.air Water.air Watercolor.air WhiteBalance.air

"$METAL_LIB" -o default.metallib default.metal-ar

rm  default.metal-ar Blend.air Brightness.air Camera.air Contrast.air \
Convolution.air CrossHatch.air DefaultShaders.air Distortion.air Exposure.air GaussianBlur.air Haze.air Invert.air Kuwahara.air \
Levels.air Mask.air OilPaint.air PerlinNoise.air Pixellate.air PolkaDot.air Saturation.air SelectiveHSL.air Sharpen.air Sketch.air \
SobelEdgeDetection.air Toon.air Vignette.air Water.air Watercolor.air WhiteBalance.air









