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

# Offers dynamic loading utilities
module dl

extern Callable
	super Pointer
	type RETURN : nullable Object

	fun call( args : nullable Object ... ) : RETURN is abstract
end

extern Procedure
	super Callable
	redef fun call( args : nullable Object ... ) : RETURN
	do
		call_intern( args )
		return null.as(RETURN) # hack to circumvent type bug :(
	end

	private fun call_intern( args : Array[ nullable Object ] ) is extern import nullable Object as( Int ), nullable Object as ( Float ), nullable Object as ( Bool ), nullable Object as ( String ), String::to_cstring, Array::length, Array::[] # TODO remove last one
end

extern Function
	super Callable
	redef type RETURN : Object

	redef fun call( args : nullable Object ... ) : RETURN
	do
		return call_intern( args )
	end

	private fun call_intern( args : Array[ nullable Object ] ) : RETURN is abstract
end

extern PointerFunction
	super Function
	redef type RETURN : Pointer

	redef fun call_intern( args ) is extern import nullable Object as( Int ), nullable Object as ( Float ), nullable Object as ( Bool ), nullable Object as ( String ), String::to_cstring, Array::length, Array::[]
end

extern FloatFunction
	super Function
	redef type RETURN : Float

	redef fun call_intern( args ) is extern import nullable Object as( Int ), nullable Object as ( Float ), nullable Object as ( Bool ), nullable Object as ( String ), String::to_cstring, Array::length, Array::[]
end

extern IntFunction
	super Function
	redef type RETURN : Int

	redef fun call_intern( args ) is extern import nullable Object as( Int ), nullable Object as ( Float ), nullable Object as ( Bool ), nullable Object as ( String ), String::to_cstring, Array::length, Array::[]
end

extern BoolFunction
	super Function
	redef type RETURN : Bool

	redef fun call_intern( args ) is extern import nullable Object as( Int ), nullable Object as ( Float ), nullable Object as ( Bool ), nullable Object as ( String ), String::to_cstring, Array::length, Array::[]
end

extern StringFunction
	super Function
	redef type RETURN : String

	redef fun call_intern( args ) is extern import String::from_cstring, nullable Object as( Int ), nullable Object as ( Float ), nullable Object as ( Bool ), nullable Object as ( String ), String::to_cstring, Array::length, Array::[]
end


extern DynamicLibrary
	super Pointer

	# lazy loading, is loaded when needed
	new open( name : String ) is extern import String::to_cstring

	# load now
	new open_now( name : String ) is extern import String::to_cstring

	#new open_with_flags( name : String, flags : Int ) is extern import String::to_cstring

	fun sym_procedure( name : String ) : Procedure is extern import String::to_cstring
	fun sym_float( name : String ) : FloatFunction is extern import String::to_cstring
	fun sym_int( name : String ) : IntFunction is extern import String::to_cstring
	fun sym_bool( name : String ) : BoolFunction is extern import String::to_cstring
	fun sym_string( name : String ) : StringFunction is extern import String::to_cstring
	fun sym_pointer( name : String ) : PointerFunction is extern import String::to_cstring

	fun []( name : String ) : Procedure do return sym_procedure( name )

	fun is_loaded : Bool is extern

	fun error : nullable String is extern import String::from_cstring, String as ( nullable String )

	fun close() is extern
end
