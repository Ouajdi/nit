linux:
	mkdir -p bin
	../../../../bin/nitc -o bin/mineit src/mineit.nit -m src/linux.nit
	../../../../bin/nitc -o bin/mineit_optimized src/optimized.nit -m src/linux.nit
	../../../../bin/nitc -o bin/mineit_persistent src/persistent.nit -m src/linux.nit
	../../../../bin/nitc --global -o bin/mineit_multiplayer src/multiplayer_launcher.nit
	../../../../bin/nitc -o bin/mineit_server src/server.nit

debug:
	../../../../bin/nitc -o bin/fbo src/fbo.nit

dd:
	../../../../bin/nitc -o bin/mineit_vr src/vr.nit -m src/linux.nit
	# -m src/optimized.nit

d:
	../../../../bin/nitc -o bin/mineit.apk src/android.nit -m ~/projects/nit/lib/android/debug.nit
	adb install -r bin/mineit.apk

v:
	../../../../bin/nitc -o bin/mineit_vr.apk src/android_vr.nit -m ~/projects/nit/lib/android/debug.nit
	adb install -r bin/mineit_vr.apk

android-release:
	../../../../bin/nitc -o bin/mineit_vr.apk --release src/android_vr.nit

android:
	mkdir -p res bin libs

	# Download `cardboard.jar`
	if [ ! -e libs/cardboard.jar ]; then \
		curl --progress-bar -o libs/cardboard.jar \
		https://raw.githubusercontent.com/googlesamples/cardboard-java/master/CardboardSample/libs/cardboard.jar; \
	fi

	# Export icon and UI images to png files with Inkscape
	../../../../contrib/inkscape_tools/bin/svg_to_icons art/icon.svg --android --out res/
	inkscape -f art/android_controls.svg -e assets/android_controls.png -y 0.0
	inkscape -f art/splash.svg -e assets/splash.png

	# Compile our programs
	../../../../bin/nitc -o bin/mineit.apk src/android.nit
	../../../../bin/nitc -o bin/mineit_vr.apk src/android_vr.nit
	../../../../bin/nitc -o bin/mineit_vr_multi.apk src/android_vr_multiplayer.nit

	# Install our programs
	adb install -r bin/mineit.apk
	adb install -r bin/mineit_vr.apk
	adb install -r bin/mineit_vr_multi.apk

icon:
	~/projects/nit/contrib/inkscape_tools/bin/svg_to_icons art/icon.svg --large --out store/

.PHONY: src/android_controls.nit
