BIN := .build/release/Blink
APP := build/Blink.app
FRAMEWORKS := /Library/Developer/CommandLineTools/Library/Developer/Frameworks
TESTLIBS := /Library/Developer/CommandLineTools/Library/Developer/usr/lib
TESTFLAGS := -Xswiftc -F -Xswiftc $(FRAMEWORKS) \
             -Xlinker -F -Xlinker $(FRAMEWORKS) \
             -Xlinker -rpath -Xlinker $(FRAMEWORKS) \
             -Xlinker -rpath -Xlinker $(TESTLIBS)

.PHONY: app test icon install run clean

app: Resources/AppIcon.icns
	swift build -c release --product Blink
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp Resources/Info.plist $(APP)/Contents/Info.plist
	cp Resources/AppIcon.icns $(APP)/Contents/Resources/AppIcon.icns
	cp $(BIN) $(APP)/Contents/MacOS/Blink
	codesign --force --sign - $(APP)

test:
	swift test $(TESTFLAGS)

icon Resources/AppIcon.icns: Tools/make-icon.swift
	swift Tools/make-icon.swift build/AppIcon.iconset
	iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns

install: app
	rm -rf /Applications/Blink.app
	cp -R $(APP) /Applications/Blink.app

run: app
	open $(APP)

clean:
	rm -rf .build build
