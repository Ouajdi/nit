all:
	mkdir -p bin/
	../../bin/nitg --dir bin src/nitcorn_hello_world.nit src/file_server_on_port_80.nit src/cgi_test.nit

xymus.net:
	mkdir -p bin/
	../../bin/nitg --dir bin/ -I ../../contrib/tnitter/src/ -I ../../contrib/benitlux/src/ -I ../../contrib/opportunity/src/ src/xymus_net.nit

cgi: all
	sudo cp bin/cgi_test /usr/lib/cgi-bin/test.cgi
