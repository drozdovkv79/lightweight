APP_NAME := Lightweight
PACKAGE_DIR := LightweightChat
EXECUTABLE := LightweightChat
BUNDLE := $(APP_NAME).app
BUNDLE_IDENTIFIER := org.peterc.lightweight
CONFIGURATION ?= release
SIGNING_IDENTITY ?= Apple Development
DISTRIBUTION_SIGNING_IDENTITY ?= Developer ID Application
DIST_DIR := dist
DIST_BUNDLE := $(DIST_DIR)/$(BUNDLE)
DIST_ARCH_FLAGS := --arch arm64 --arch x86_64
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

.PHONY: all build bundle sign verify register run dist dist-build dist-bundle dist-sign dist-verify clean

all: register

build:
	swift build -c $(CONFIGURATION) --package-path $(PACKAGE_DIR)

bundle: build
	mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	cp $(PACKAGE_DIR)/.build/$(CONFIGURATION)/$(EXECUTABLE) $(BUNDLE)/Contents/MacOS/$(EXECUTABLE)
	cp $(PACKAGE_DIR)/Resources/Info.plist $(BUNDLE)/Contents/Info.plist
	cp $(PACKAGE_DIR)/Resources/AppIcon.icns $(BUNDLE)/Contents/Resources/AppIcon.icns

sign: bundle
	codesign --force --sign "$(SIGNING_IDENTITY)" --identifier $(BUNDLE_IDENTIFIER) $(BUNDLE)

verify: sign
	codesign --verify --deep --strict --verbose=2 $(BUNDLE)

register: verify
	$(LSREGISTER) -f "$(CURDIR)/$(BUNDLE)"

run: register
	open $(BUNDLE)

# Distribution builds stay separate so local builds remain native and quick.
# dist-sign requires a Developer ID Application certificate.
dist: dist-verify

dist-build:
	swift build -c release $(DIST_ARCH_FLAGS) --package-path $(PACKAGE_DIR)

dist-bundle: dist-build
	mkdir -p $(DIST_BUNDLE)/Contents/MacOS $(DIST_BUNDLE)/Contents/Resources
	bin_dir="$$(swift build -c release $(DIST_ARCH_FLAGS) --package-path $(PACKAGE_DIR) --show-bin-path)"; \
	cp "$$bin_dir/$(EXECUTABLE)" $(DIST_BUNDLE)/Contents/MacOS/$(EXECUTABLE)
	cp $(PACKAGE_DIR)/Resources/Info.plist $(DIST_BUNDLE)/Contents/Info.plist
	cp $(PACKAGE_DIR)/Resources/AppIcon.icns $(DIST_BUNDLE)/Contents/Resources/AppIcon.icns

dist-sign: dist-bundle
	codesign --force --options runtime --timestamp --sign "$(DISTRIBUTION_SIGNING_IDENTITY)" --identifier $(BUNDLE_IDENTIFIER) $(DIST_BUNDLE)

dist-verify: dist-sign
	codesign --verify --deep --strict --verbose=2 $(DIST_BUNDLE)
	lipo $(DIST_BUNDLE)/Contents/MacOS/$(EXECUTABLE) -verify_arch arm64 x86_64

clean:
	swift package --package-path $(PACKAGE_DIR) clean
