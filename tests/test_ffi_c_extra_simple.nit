
in "C" `{
	#include <stdio.h>
`}

class A
	fun foo `{
		printf( "foo from C\n" );
	`}

	fun bar( other : A, i : Int ) `{
		printf( "bar from C: %d\n", i );
	`}

	fun baz( i : Int ) : Int `{
		return i * 2;
	`}

	fun titi( i : Float ) : Float `{
		printf( "titi from C: %f\n", i );
		return i*2.0f; // i * 12;
	`}

	fun bounce( a : A ) : A `{
		return a;
	`}
end

var a = new A
a.foo
a.bar( a, 144 )
print "From Nit: {a.baz( 121 )}"
print "From Nit: {a.titi( 2.34 )}"
print a == a.bounce( a )
