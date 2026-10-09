# amakawa build helpers.  Usage: make <target>
# Requires Flutter (stable, >= 3.47) on PATH.  See BUILD.md.

FLUTTER ?= flutter
NATIVE_TEST_DIR := build/native_test

.PHONY: help deps l10n analyze test test-native macos macos-dmg windows android clean

help:
	@echo "Targets:"
	@echo "  deps         flutter pub get"
	@echo "  l10n         regenerate localization code from lib/l10n/*.arb"
	@echo "  analyze      static analysis"
	@echo "  test         Dart tests + C++ DSP test"
	@echo "  test-native  build + run the C++ DSP unit test (needs g++/clang++)"
	@echo "  macos        release build -> build/macos/Build/Products/Release/amakawa.app"
	@echo "  macos-dmg    macos + package build/amakawa-macos.dmg"
	@echo "  windows      release build (on Windows prefer scripts/build_windows.ps1)"
	@echo "  android      release APK -> build/app/outputs/flutter-apk/app-release.apk"
	@echo "  clean"

deps:
	$(FLUTTER) pub get

l10n: deps
	$(FLUTTER) gen-l10n

analyze: deps
	$(FLUTTER) analyze

test: deps test-native
	$(FLUTTER) test

test-native:
	mkdir -p $(NATIVE_TEST_DIR)
	$(CXX) -O2 -std=c++17 -Wall -Wextra -o $(NATIVE_TEST_DIR)/dsp_test \
		packages/amakawa_core/test_native/dsp_test.cpp packages/amakawa_core/src/dsp.cpp
	$(NATIVE_TEST_DIR)/dsp_test

macos: deps
	$(FLUTTER) config --enable-macos-desktop
	$(FLUTTER) build macos --release

macos-dmg: macos
	rm -rf build/dmg && mkdir -p build/dmg
	cp -R build/macos/Build/Products/Release/amakawa.app build/dmg/
	ln -s /Applications build/dmg/Applications
	hdiutil create -volname "amakawa" -srcfolder build/dmg -ov -format UDZO build/amakawa-macos.dmg
	@echo "Created build/amakawa-macos.dmg"

# On Windows, run from PowerShell instead:  .\scripts\build_windows.ps1
windows: deps
	$(FLUTTER) config --enable-windows-desktop
	$(FLUTTER) build windows --release

android: deps
	$(FLUTTER) build apk --release

clean:
	$(FLUTTER) clean
	rm -rf build
