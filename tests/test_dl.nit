import dl

var lib = new DynamicLibrary.open( "libm.so" ) # load lib
if not lib.is_loaded then
	var error = lib.error
	if error != null then print "DL error: {error}"
else
	var f = lib.sym_float( "sqrtf" ) # load function
	var r = f.call( 120.0 ) # call function
	print "sqrtf(120.0) = {r}"

	var error = lib.error
	if error != null then print "DL error: {error}"

	f = lib.sym_float( "fmaf" )
	r = f.call( 1.1, 22.22, 100.1 )
	print "ceill(12.345) = {r}"

	error = lib.error
	if error != null then print "DL error: {error}"

	f = lib.sym_float( "nonexistant" )
	error = lib.error
	if error != null then print "Expected DL error: cannot load symbol"

	lib.close
end

lib = new DynamicLibrary.open( "libnonexistant.so" )
if not lib.is_loaded then
	var error = lib.error
	if error != null then print "Expected DL error: {error}"
end

