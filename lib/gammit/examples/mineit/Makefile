# Compile all alternative versions for GNU/Linux
linux: assets/splash.png
	mkdir -p bin

	# Core and best alternatives
	../../../../bin/nitc -o bin/mineit_core src/mineit.nit -m src/linux.nit
	../../../../bin/nitc -o bin/mineit src/persistent_binary.nit -m src/linux.nit

	# More alternatives (multiplayer, VR and optimized)
	../../../../bin/nitc -o bin/mineit_optimized src/optimized.nit -m src/linux.nit
	../../../../bin/nitc --global -o bin/mineit_multiplayer src/multiplayer_launcher.nit
	../../../../bin/nitc -o bin/mineit_server src/server.nit
	../../../../bin/nitc -o bin/mineit_vr src/vr.nit -m src/linux.nit

# Compile 3 different versions for Android
android: assets/splash.png assets/android_controls.png res/drawable-hdpi/icon.png libs/cardboard.jar
	mkdir -p bin

	../../../../bin/nitc -o bin/mineit.apk src/android.nit
	../../../../bin/nitc -o bin/mineit_vr.apk src/android_vr.nit
	../../../../bin/nitc -o bin/mineit_vr_multi.apk src/android_vr_multiplayer.nit

	adb install -r bin/mineit.apk
	adb install -r bin/mineit_vr.apk
	adb install -r bin/mineit_vr_multi.apk

# Splash screen
assets/splash.png: art/splash.svg
	mkdir -p assets
	inkscape -f art/splash.svg -e assets/splash.png

# Android control overlay
assets/android_controls.png: art/android_controls.svg
	mkdir -p assets
	inkscape -f art/android_controls.svg -e assets/android_controls.png -y 0.0

# Android icons
res/drawable-hdpi/icon.png: art/icon.svg
	mkdir -p res
	../../../../contrib/inkscape_tools/bin/svg_to_icons art/icon.svg --android --out res/

# Download `cardboard.jar`
libs/cardboard.jar:
	curl --progress-bar -o libs/cardboard.jar \
	https://raw.githubusercontent.com/googlesamples/cardboard-java/master/CardboardSample/libs/cardboard.jar

# Generate large icons for the Web
pub/512.png:
	mkdir -p pub
	../../../../contrib/inkscape_tools/bin/svg_to_icons art/icon.svg --large --out pub/

v:
	../../../../bin/nitc --semi-global -o bin/mineit_vr.apk src/android_vr.nit -m ~/projects/nit/lib/android/debug.nit
	adb install -r bin/mineit_vr.apk
