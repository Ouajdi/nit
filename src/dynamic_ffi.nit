# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2012 Alexis Laferrière <alexis.laf@xymus.net>
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

# Dynamic FFI used by interpreter, manages preparation, compilation and
# loading of foreign code.
module dynamic_ffi

#import dynamic_compiler
import modelbuilder
import naive_interpreter

# For dynamic compilers
import dlni_compiler
import common_ffi

in "C Header" `{
#include <dlfcn.h>

	typedef union u_native_call_stack_t {
		Instance instance; /* void* in lib */
		int int_v;
		float float_v;
	} native_call_stack_t;

typedef int (*nit_dlni_entry)(int,native_call_stack_t*,native_call_stack_t*);
typedef nit_dlni_entry (*nit_dlni_ready_call)( const char* name );

union s_nit_dlni_ready_call {
	void *handle;
	nit_dlni_ready_call fun;
};
`}

in "C Body" `{
	native_call_stack_t native_call_stack[1024];
	int native_call_stack_pointer = 0;


native_call_stack_t * native_call_fill_stack( Array args ) {
		int len = Array_length( args );
		int a;
		native_call_stack_t *nargs = native_call_stack + native_call_stack_pointer; // calloc( sizeof(Instance), len );
		native_call_stack_pointer += len;
		for ( a = 0; a < len; a ++ ) {
		  Instance arg = Object_as_Instance( Object_as_not_null( Array__index( args, a ) ) );
			if ( Instance_is_a_PrimitiveInstance( arg ) ) {
				PrimitiveInstance parg = Instance_as_PrimitiveInstance( arg );
				Object val = PrimitiveInstance_val( parg );
				if ( Object_is_a_Int( val ) ) {
					nargs[ a ].int_v = Object_as_Int( val );
				}
				else if ( Object_is_a_Float( val ) ) {
					nargs[ a ].float_v = Object_as_Float( val );
				}
			}
			else
				nargs[ a ].instance = arg;
		}

		return nargs;
	}
`}

extern DLNILib
	new dlopen( path : String ) import String::to_cstring `{
		void* handle = dlopen( String_to_cstring( path ), RTLD_LOCAL | RTLD_NOW );
		if ( handle == NULL ) {
			printf( "dlerror: %s\n", dlerror() );
			exit(1);
		}
		return handle;
	`}
	
	fun get_dlni_ready_call : DLNIReadyCall `{
		return dlsym( recv, "NitReadyCall" );
	`}
end

extern DLNIEntry`{ nit_dlni_entry `}
	fun native_call_int( args : Array[Instance] ) : Int import Array::[], Array::length, Instance as nullable, Instance as (PrimitiveInstance[Object]), PrimitiveInstance::val, Object as (Instance), Object as not nullable, Object as (Int) `{
		int len = Array_length( args );
		native_call_stack_t *nargs = native_call_fill_stack( args );

		int dlni_result;
		native_call_stack_t meth_result;
		dlni_result = ((nit_dlni_entry)recv)( len, nargs, &meth_result );
		native_call_stack_pointer -= len;
		if ( dlni_result != 0 ) {
			printf( "Error in DLNI: %d", dlni_result );
			exit( 1 );
		}

		return meth_result.int_v;
	`}
	fun native_call_float( args : Array[Instance] ) : Float import Array::[], Array::length, Instance as nullable, Instance as (PrimitiveInstance[Object]), PrimitiveInstance::val, Object as (Float) `{
		int len = Array_length( args );
		native_call_stack_t *nargs = native_call_fill_stack( args );

		int dlni_result;
		native_call_stack_t meth_result;
		dlni_result = ((nit_dlni_entry)recv)( len, nargs, &meth_result );
		native_call_stack_pointer -= len;
		if ( dlni_result != 0 ) {
			printf( "Error in DLNI: %d", dlni_result );
			exit( 1 );
		}

		return meth_result.float_v;
	`}
	fun native_call_instance( args : Array[Instance] ) : Instance import Array::[], Array::length, Instance as nullable, Instance as (PrimitiveInstance[Object]), PrimitiveInstance::val, Object as (Float) `{
		int len = Array_length( args );
		native_call_stack_t *nargs = native_call_fill_stack( args );

		int dlni_result;
		native_call_stack_t meth_result;
		dlni_result = ((nit_dlni_entry)recv)( len, nargs, &meth_result );
		native_call_stack_pointer -= len;
		if ( dlni_result != 0 ) {
			printf( "Error in DLNI: %d", dlni_result );
			exit( 1 );
		}

		return meth_result.instance;
	`}
	fun native_call_proc( args : Array[Instance] ) import Array::[], Array::length, Instance as nullable, Instance as (PrimitiveInstance[Object]), PrimitiveInstance::val, Object as (Int) `{
		int len = Array_length( args );
		native_call_stack_t *nargs = native_call_fill_stack( args );

		int dlni_result;
		native_call_stack_t meth_result;
		dlni_result = ((nit_dlni_entry)recv)( len, nargs, &meth_result );
		native_call_stack_pointer -= len;
		if ( dlni_result != 0 ) {
			printf( "Error in DLNI: %d", dlni_result );
			exit( 1 );
		}
	`}
end

extern DLNIReadyCall `{ nit_dlni_ready_call `} # TODO rename to get_entry?
	fun get_dlni_entry( meth_name : String ) : DLNIEntry import String::to_cstring `{
		char* meth_cname = String_to_cstring( meth_name );
		union s_nit_dlni_ready_call ready;
		ready.handle = recv;

		return ready.fun( meth_cname );
	`}
end

redef class AExternMethPropdef
	var foreign_entry_handle : nullable DLNIEntry

	redef fun normal_ffi_call(v, mpropdef, args)
	# redef fun call(v, mpropdef, args) # TODO make main
	do
		var entry = foreign_entry_handle
		if entry == null then
			# retreive from module
			var amodule = v.modelbuilder.mmodule2nmodule[ mpropdef.mclassdef.mmodule ]
			var ready = amodule.foreign_code_ready_call( v )

			# get handle to meth
			entry = ready.get_dlni_entry( mpropdef.cname )

			# TODO debug false warning
			if entry.is_null then v.fatal( "Error: unable to find method {self} in foreign code library." )

			# cache result
			foreign_entry_handle = entry
		end

		# do actual call
		var rmt = mpropdef.msignature.return_mtype
		if rmt == null then
			entry.native_call_proc( args )
			return null
		else if rmt isa MClassType then
			var rname = rmt.mclass.name
			if rname == "Int" then
				return new PrimitiveInstance[Int]( rmt, entry.native_call_int( args ) )
			else if rname == "Float" then
				return new PrimitiveInstance[Float]( rmt, entry.native_call_float( args ) )
			else
				return entry.native_call_instance( args )
			end
		end

		print "Extern method return type not recognized"
		abort
	end
end

redef class AModule
	private var foreign_code_lib_intern : nullable DLNILib = null
	private var foreign_code_ready_call_intern : nullable DLNIReadyCall = null

	private fun foreign_code_lib_path : String
	do
		var src = location.file
		assert src != null else print "Error: module {mmodule.name} has no source, can't find foreign code library."

		var dir = src.filename.dirname
		var base = src.filename.basename( ".nit" )
		return "{dir}/{base}.so"
	end

	fun foreign_code_lib( v : NaiveInterpreter ) : DLNILib
	do
		var lib = foreign_code_lib_intern
		if lib != null then return lib

		# Compile lib
		compile_foreign_code( v )

		lib = new DLNILib.dlopen( foreign_code_lib_path )
		if lib.is_null then v.fatal( "Error: cannot find foreign code library for {mmodule.name}" )

		foreign_code_lib_intern = lib
		return lib
	end

	fun foreign_code_ready_call( v : NaiveInterpreter ) : DLNIReadyCall
	do
		var ready = foreign_code_ready_call_intern
		if ready != null then return ready

		var lib = foreign_code_lib( v )
		ready = lib.get_dlni_ready_call
		if ready.is_null then v.fatal( "Error: symbol \"NitReadyCall\" not found in library" )

		foreign_code_ready_call_intern = ready
		return ready
	end

	fun compile_foreign_code( v : NaiveInterpreter )
	do
		var compdir = ".nit_compile"
		compdir.mkdir

		var ffi_compiler = once new FFICompiler( v.modelbuilder )
		var dlni_compiler = once new DLNICompiler( v.modelbuilder )

		# FFI and NI related checks
		ffi_compiler.verify_foreign_code( self )
		dlni_compiler.verify_nitni( self )

		ffi_compiler.compile_ffi_wrapper( self, compdir )
		dlni_compiler.compile_dlni( self, compdir )

		var srcs = new Array[String]
		srcs.add_all( ffi_compiler.files )
		srcs.add_all( dlni_compiler.files )

		var objs = new Array[String]
		for f in srcs do
			var obj = "{compdir}/{f.basename( ".c" )}.o"
			var cmd = "gcc -Wall -c -fPIC -I {compdir} -g -o {obj} {f}"
			assert sys.system( cmd ) == 0 else print "Failed to compile C code: {cmd}"
			objs.add( obj )
		end
		var so = foreign_code_lib_path
		var cmd = "gcc -Wall -shared -Wl,-soname,{mmodule.name}.so -g -o {so} {objs.join(" ")}"
		assert sys.system( cmd ) == 0 else print "Failed to link native code: {cmd}"
	end
end

redef extern Pointer
	fun is_null : Bool `{ return recv == NULL; `}
end
