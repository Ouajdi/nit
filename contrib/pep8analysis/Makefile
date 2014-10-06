bin/pep8analysis:
	mkdir -p bin
	../../bin/nitg --global -o bin/pep8analysis src/pep8analysis.nit

doc/index.html:
	../../bin/nitdoc src/pep8analysis.nit

tests: bin/pep8analysis
	bin/pep8analysis --cfg-long tests/privat/*.pep tests/micro/*.pep tests/terrasa/*.pep

www/pep8analysis.js:
	../../bin/nitg -o www/pep8analysis.js --semi-global src/pep8analysis_web.nit
	mkdir -p www/samples
	cp tests/micro/*.pep tests/privat/02-fibo.pep tests/privat/06-calc-non-pur.pep www/samples

cgi:
	../../bin/nitg -o bin/cgi src/pep8analysis_cgi.nit
	sudo cp bin/cgi /usr/lib/cgi-bin/pep8.cgi

.PHONY: bin/pep8analysis tests doc/index.html www/pep8analysis.js
