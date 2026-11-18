ARCHS = arm64 arm64e
TARGET := iphone:clang:14.5:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Extrude

Extrude_FILES = $(wildcard Sources/*.m) $(wildcard Sources/*.mm)
Extrude_FRAMEWORKS = UIKit CoreGraphics Foundation
Extrude_PRIVATE_FRAMEWORKS = 
Extrude_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-function -Wno-error
Extrude_CODESIGN_FLAGS = -Sentitlements.plist
Extrude_INSTALL_PATH = /var/jb/Applications

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "uicache -p /var/jb/Applications/Extrude.app"
