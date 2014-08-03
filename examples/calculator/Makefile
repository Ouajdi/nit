all:
	mkdir -p bin/ res/
	../../contrib/inkscape_tools/bin/svg_to_icons art/icon.svg --android --out res/
	../../bin/nitg --dir bin/ src/calculator_gtk.nit src/calculator_test.nit src/calculator_android.nit
