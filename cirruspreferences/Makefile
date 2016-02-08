ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

BUNDLE_NAME = cirrusPreferences
cirrusPreferences_FILES = cirrusPreferences.mm
cirrusPreferences_INSTALL_PATH = /Library/PreferenceBundles
cirrusPreferences_FRAMEWORKS = UIKit
cirrusPreferences_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/cirrusPreferences.plist$(ECHO_END)
