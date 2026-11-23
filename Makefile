BIN := .build/release/Blink
APP := build/Blink.app
IDENTITY := Blink Local Signing
# The local identity from `make cert` when present, so the Accessibility grant survives rebuilds.
SIGN := $(shell security find-identity -v -p codesigning 2>/dev/null | grep -q '"$(IDENTITY)"' && echo '$(IDENTITY)' || echo -)
FRAMEWORKS := /Library/Developer/CommandLineTools/Library/Developer/Frameworks
TESTLIBS := /Library/Developer/CommandLineTools/Library/Developer/usr/lib
PLUGINS := /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing
TESTFLAGS := -Xswiftc -F -Xswiftc $(FRAMEWORKS) \
             -Xswiftc -plugin-path -Xswiftc $(PLUGINS) \
             -Xlinker -F -Xlinker $(FRAMEWORKS) \
             -Xlinker -rpath -Xlinker $(FRAMEWORKS) \
             -Xlinker -rpath -Xlinker $(TESTLIBS)

.PHONY: app test icon install run clean cert

app: Resources/AppIcon.icns
	swift build -c release --product Blink
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp Resources/Info.plist $(APP)/Contents/Info.plist
	cp Resources/AppIcon.icns $(APP)/Contents/Resources/AppIcon.icns
	cp $(BIN) $(APP)/Contents/MacOS/Blink
	codesign --force --sign "$(SIGN)" $(APP)

test:
	swift test $(TESTFLAGS)

icon Resources/AppIcon.icns: Tools/make-icon.swift
	swift Tools/make-icon.swift build/AppIcon.iconset
	iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns

install: app
	-pkill -x Blink
	rm -rf /Applications/Blink.app
	cp -R $(APP) /Applications/Blink.app
	open /Applications/Blink.app

cert:
	Tools/make-cert.sh

run: app
	open $(APP)

clean:
	rm -rf .build build
