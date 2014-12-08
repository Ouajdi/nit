linux:
	mkdir -p bin
	../../../../bin/nitc -o bin/mineit src/mineit.nit -m src/linux.nit
	../../../../bin/nitc -o bin/mineit_optimized src/optimized.nit -m src/linux.nit
	../../../../bin/nitc -o bin/mineit_persistent src/persistent.nit -m src/linux.nit
	../../../../bin/nitc --global -o bin/mineit_multiplayer src/multiplayer_launcher.nit
	../../../../bin/nitc -o bin/mineit_server src/server.nit

debug:
	../../../../bin/nitc -o bin/mineit_vr.apk src/android_vr.nit
	adb install -r bin/mineit_vr.apk

android:
	mkdir -p res bin
	../../../../contrib/inkscape_tools/bin/svg_to_icons art/icon.svg --android --out res/
	inkscape -f art/android_controls.svg -e assets/android_controls.png -y 0.0
	../../../../bin/nitc -o bin/mineit.apk src/android.nit
	adb install -r bin/mineit.apk
	../../../../bin/nitc -o bin/mineit_vr.apk src/android_vr.nit
	adb install -r bin/mineit_vr.apk
	../../../../bin/nitc -o bin/mineit_vr_multi.apk src/android_vr_multiplayer.nit
	adb install -r bin/mineit_vr_multi.apk

icon:
	~/projects/nit/contrib/inkscape_tools/bin/svg_to_icons art/icon.svg --large --out store/

.PHONY: src/android_controls.nit
