import python

in "Python" `{
	from math import pow
	print "bub"
`}

class A
	fun bar
	do
		# normal Nit method
		print "from Nit"
	end

	fun foo : Int in "Python" `{
		# python method!
		print 1111
		print False
		print True
		print pow( 10, 4 )
		f = open( "/tmp/pynit", 'w+' )
		f.write( "allo" )
		f.close
		return 999
	`}

	fun baz( a : Int, b : Bool, c : Float ) in "Python" `{
		print a
		print b
		print c
	`}

	# TODO add when functionnal
	#fun callback( a : A ) import bar in "Python" `{
		#a.bar
	#`}
end

var a = new A
print a.foo
a.baz( 1234, false, 4.567 )
#a.callback( a )
