APP_NAME := Lightweight
PACKAGE_DIR := LightweightChat
EXECUTABLE := LightweightChat
BUNDLE := $(APP_NAME).app
SIGNING_IDENTITY ?= Apple Development
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

.PHONY: all build bundle sign verify register run clean

all: register

build:
	swift build --package-path $(PACKAGE_DIR)

bundle: build
	mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	cp $(PACKAGE_DIR)/.build/debug/$(EXECUTABLE) $(BUNDLE)/Contents/MacOS/$(EXECUTABLE)
	cp $(PACKAGE_DIR)/Resources/Info.plist $(BUNDLE)/Contents/Info.plist
	cp $(PACKAGE_DIR)/Resources/AppIcon.icns $(BUNDLE)/Contents/Resources/AppIcon.icns

sign: bundle
	codesign --force --sign "$(SIGNING_IDENTITY)" --identifier com.lightweight.chat $(BUNDLE)

verify: sign
	codesign --verify --deep --strict --verbose=2 $(BUNDLE)

register: verify
	$(LSREGISTER) -f "$(CURDIR)/$(BUNDLE)"

run: register
	open $(BUNDLE)

clean:
	swift package --package-path $(PACKAGE_DIR) clean
