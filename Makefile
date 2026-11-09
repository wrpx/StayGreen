APP_NAME = StayGreen
BUNDLE_DIR = build/$(APP_NAME).app
CONTENTS_DIR = $(BUNDLE_DIR)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources
INSTALL_DIR = /Applications/$(APP_NAME).app

.PHONY: all icon build install run clean

all: build

icon: Resources/AppIcon.icns

Resources/AppIcon.icns: scripts/generate-icon.swift
	@mkdir -p build Resources
	@swift scripts/generate-icon.swift
	@iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns
	@rm -rf build/AppIcon.iconset

ARCH = $(shell uname -m)

build: Resources/AppIcon.icns
	@mkdir -p "$(MACOS_DIR)" "$(RESOURCES_DIR)"
	swiftc -O -target $(ARCH)-apple-macos14.0 Sources/main.swift -o "$(MACOS_DIR)/$(APP_NAME)" \
		-framework Cocoa -framework CoreGraphics -framework IOKit
	cp Resources/Info.plist "$(CONTENTS_DIR)/Info.plist"
	cp Resources/AppIcon.icns "$(RESOURCES_DIR)/AppIcon.icns"
	codesign --force --deep --sign - "$(BUNDLE_DIR)"
	@echo "✅ Built $(BUNDLE_DIR)"

LSREGISTER = /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

install: build
	@pkill -x "$(APP_NAME)" 2>/dev/null || true
	@pkill -x "TeamsGreen" 2>/dev/null || true
	-@$(LSREGISTER) -u "$(CURDIR)/$(BUNDLE_DIR)" 2>/dev/null || true
	rm -rf "$(INSTALL_DIR)"
	cp -R "$(BUNDLE_DIR)" "$(INSTALL_DIR)"
	rm -rf build
	@swift -e 'import Cocoa; if let img = NSImage(contentsOfFile: "Resources/AppIcon.icns") { NSWorkspace.shared.setIcon(img, forFile: "$(INSTALL_DIR)", options: []) }'
	touch "$(INSTALL_DIR)"
	-@$(LSREGISTER) -f "$(INSTALL_DIR)" 2>/dev/null || true
	@echo "🚀 Installed to $(INSTALL_DIR)"

run: install
	open "$(INSTALL_DIR)"

clean:
	rm -rf build
