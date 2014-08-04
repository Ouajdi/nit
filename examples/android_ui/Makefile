android:
	mkdir -p bin/ res/
	../../contrib/inkscape_tools/bin/svg_to_icons art/icon.svg --android --out res/
	../../bin/nitg -o bin/ui.apk src/android_ui.nit

install: android
	adb install -r bin/ui.apk

clean:
	rm -rf bin
