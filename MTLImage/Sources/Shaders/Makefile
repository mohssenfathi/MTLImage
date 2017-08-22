XCODE = '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform'
METAL = '$(XCODE)/usr/bin/metal'
METAL_AR = '$(XCODE)/usr/bin/metal-ar'
METAL_LIB = '$(XCODE)/usr/bin/metallib'
SDK = '$(XCODE)/Developer/SDKs/iPhoneOS.sdk'
SRC = $(wildcard *.metal)
OBJ = $(patsubst %.metal, %.air, $(SRC))

default: $(SRC)
	make clean
	make $(OBJ)
	$(METAL_AR) r default.metal-ar $(OBJ)
	$(METAL_LIB) -o default.metallib default.metal-ar
	rm -f *.air *.metal-ar

%.air: %.metal
	$(METAL) -arch air64 -emit-llvm -c -ffast-math -miphoneos-version-min=8.0 -std=ios-metal1.1 $< -o $@

%.metal-ar: %.air
	$(METAL_AR) r $(OBJ)
		metal-ar r $@ $<

%.metallib: %.metal-ar
		metallib -o $@ $<

clean:
	rm -f *.metallib *.metal-ar *.air
