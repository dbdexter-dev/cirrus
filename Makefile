ARCHS = armv7 armv7s arm64
include theos/makefiles/common.mk

TWEAK_NAME = Cirrus
Cirrus_FILES = Tweak.xm CirrusLockScreen.xm 
Cirrus_FRAMEWORKS = UIKit CoreGraphics CoreLocation
Cirrus_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/
Cirrus__LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk

after-Cirrus-stage::
	mkdir -p $(THEOS_STAGING_DIR)/Library/Application\ Support/Cirrus
	cp Resources/* $(THEOS_STAGING_DIR)/Library/Application\ Support/Cirrus
after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += cirruspreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
