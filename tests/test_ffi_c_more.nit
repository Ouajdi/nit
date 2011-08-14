# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2011 Alexis Laferrière <alexis.laf@xymus.net>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

in "C header" `{
	#include <stdio.h>
`}

in "C" `{
	void f( char *str ) {
		printf( "%s\n", str );
	}
`}

`{
	void g() {
		printf( "from C\n" );
	}
`}

extern A
	new is extern `{ return malloc(1); `}
	new new_implicit `{ return malloc(1); `}
	new new_in_language is extern in "C" `{ return malloc(1); `}
	new new_in_language_implicit in "C" `{ return malloc(1); `}

	fun m : Int is extern `{ return 10; `}

	fun n : String is extern import String::from_cstring `{
		return new_String_from_cstring( "allo" );
	`}

	fun o ( str : String ) is extern import String::to_cstring `{
		f( String_to_cstring( str ) );
	`}

	fun p : Int import m `{
		return A_m( recv ) + 5;
	`}

	fun in_language : Int is extern in "C" `{
		return  4;
	`}
	fun in_language_implicit : Int in "C" `{
		return  4;
	`}
	fun simple_implicit `{
		g();
	`}
	fun inline_implicit : Int `{ return  7; `}
end

extern B
special A
end

extern C `{int*`}
end

extern D
special C
end

extern E
special C
end

var a = new A
print a.m
print a.n
a.o( "hello" )
print a.p
