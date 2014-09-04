all: server

server:
	mkdir -p bin/
	../../bin/nitc --dir bin/ src/benitlux_daily.nit src/benitlux_web.nit

bin/benitlux.apk: src/benitlux_serial.nit
	mkdir -p bin/ res/
	../inkscape_tools/bin/svg_to_icons art/icon.svg --android --out res/
	../../bin/nitc -o bin/benitlux.apk src/benitlux_android.nit -m src/benitlux_serial.nit
	adb install -r bin/benitlux.apk

src/benitlux_serial.nit:  $(shell nitls -M src/benitlux_android.nit)
	../../bin/nitserial -o $@ src/benitlux_android.nit

.PHONY: src/benitlux_serial.nit
