android:
	mkdir -p bin/ res/
	../../../contrib/inkscape_tools/bin/svg_to_icons art/icon.svg --android --out res/
	../../../bin/nitg --dir bin/ src/ui_test.nit
	adb install -r bin/ui_test.apk

install: android
	adb install -r bin/ui.apk

clean:
	rm -rf bin
