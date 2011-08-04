/* This file is part of NIT ( http://www.nitlanguage.org ).
 *
 * Copyright 2011 Alexis Laferrière <alexis.laf@xymus.net>
 *
 * This file is free software, which comes along with NIT.  This software is
 * distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A
 * PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
 * is kept unaltered, and a notification of the changes is added.
 * You  are  allowed  to  redistribute it and sell it, alone or is a part of
 * another product.
 */

#include "dl.nit.h"

#include <dlfcn.h>

#define TYPE_FLOAT 'f'
#define TYPE_INT 'i'
#define TYPE_BOOL 'b'
#define TYPE_STRING 's'
#define TYPE_NULL 'n'
union stack_item_value {
	float f;
	bigint i;
	int b;
	char *s;
};
struct stack_item {
	char type; /* float->f, int->i, bool->b, char*->s, null->n */
	union stack_item_value value;
};
#define EXTRACT_ITEM( si ) (si.type == TYPE_FLOAT? (bigint)si.value.f : si.type == TYPE_STRING? (bigint)si.value.s : si.type == TYPE_BOOL? (bigint)si.value.b : si.value.i )

#define EXTRACT_STACK(c,stack) EXTRACT_STACK_##c(stack)
#define EXTRACT_STACK_0( stack ) void
#define EXTRACT_STACK_1( stack ) EXTRACT_ITEM( stack[ 0 ] )
#define EXTRACT_STACK_2( stack ) EXTRACT_STACK_1( stack ), EXTRACT_ITEM( stack[ 1 ] )
#define EXTRACT_STACK_3( stack ) EXTRACT_STACK_2( stack ), EXTRACT_ITEM( stack[ 2 ] )
#define EXTRACT_STACK_4( stack ) EXTRACT_STACK_3( stack ), EXTRACT_ITEM( stack[ 3 ] )
#define EXTRACT_STACK_5( stack ) EXTRACT_STACK_4( stack ), EXTRACT_ITEM( stack[ 4 ] )
#define EXTRACT_STACK_6( stack ) EXTRACT_STACK_5( stack ), EXTRACT_ITEM( stack[ 5 ] )
#define EXTRACT_STACK_7( stack ) EXTRACT_STACK_6( stack ), EXTRACT_ITEM( stack[ 6 ] )
#define EXTRACT_STACK_8( stack ) EXTRACT_STACK_7( stack ), EXTRACT_ITEM( stack[ 7 ] )
#define EXTRACT_STACK_9( stack ) EXTRACT_STACK_8( stack ), EXTRACT_ITEM( stack[ 8 ] )
#define EXTRACT_STACK_10( stack ) EXTRACT_STACK_9( stack ), EXTRACT_ITEM( stack[ 9 ] )

#define PARAMS(c) PARAMS_##c
#define PARAMS_0 void
#define PARAMS_1 bigint
#define PARAMS_2 PARAMS_1, bigint
#define PARAMS_3 PARAMS_2, bigint
#define PARAMS_4 PARAMS_3, bigint
#define PARAMS_5 PARAMS_4, bigint
#define PARAMS_6 PARAMS_5, bigint
#define PARAMS_7 PARAMS_6, bigint
#define PARAMS_8 PARAMS_7, bigint
#define PARAMS_9 PARAMS_8, bigint
#define PARAMS_10 PARAMS_9, bigint

/*result = (*( (float (*)( PARAMS( argc ) ))recv ))( EXTRACT_STACK(argc,native_args) );*/
#define DLCALL( argc, return_type ) switch( argc ) { \
case 0: result = (*( (return_type (*)( PARAMS_0 ) ))recv ))( EXTRACT_STACK_0(native_args) ) \
break; \
case 1: result = (*( (return_type (*)( PARAMS_1 ) ))recv ))( EXTRACT_STACK_1(native_args) ) \
break; \
case 2: result = (*( (return_type (*)( PARAMS_2 ) ))recv ))( EXTRACT_STACK_2(native_args) ) \
break; \
case 3: result = (*( (return_type (*)( PARAMS_3 ) ))recv ))( EXTRACT_STACK_3(native_args) ) \
break; \
case 4: result = (*( (return_type (*)( PARAMS_4 ) ))recv ))( EXTRACT_STACK_4(native_args) ) \
break; \
case 5: result = (*( (return_type (*)( PARAMS_5 ) ))recv ))( EXTRACT_STACK_5(native_args) ) \
break; \
case 6: result = (*( (return_type (*)( PARAMS_6 ) ))recv ))( EXTRACT_STACK_6(native_args) ) \
break; \
case 7: result = (*( (return_type (*)( PARAMS_7 ) ))recv ))( EXTRACT_STACK_7(native_args) ) \
break; \
case 8: result = (*( (return_type (*)( PARAMS_8 ) ))recv ))( EXTRACT_STACK_8(native_args) ) \
break; \
case 9: result = (*( (return_type (*)( PARAMS_9 ) ))recv ))( EXTRACT_STACK_9(native_args) ) \
break; \
case 10: result = (*( (return_type (*)( PARAMS_10 ) ))recv ))( EXTRACT_STACK_10(native_args) ) \
break; \
default: \
}

#define NITDL_CALL( result_decl, return_type, result_assign, return_result )	int i,\
		argc;\
	struct stack_item *native_args;\
	nullable_Object value;\
	nitdl_func_ptr_converter c;\
	result_decl;\
	c.ptr = recv; /*this avoids the "conversion of object pointer to function pointer" warning*/\
	\
	nitdl_fill_stack( args, &native_args, &argc );\
	\
	result_assign(*( (return_type (*)( PARAMS( 10 ) ))c.func ))( EXTRACT_STACK(10,native_args) );\
	free( native_args );\
	return_result;


void nitdl_fill_stack( Array args, struct stack_item **native_args_ptr, int *argc_ptr )
{
	int i,
		argc;
	nullable_Object value;
	struct stack_item *native_args;

	argc = Array_length( args );
	native_args = malloc( 10 * sizeof(struct stack_item) );

	for ( i = 0; i < argc; i ++ )
	{
		value = Array__index( args, i );

		if ( nullable_Object_is_a_Float( value ) )
		{
			native_args[ i ].type = TYPE_FLOAT;
			native_args[ i ].value.f = nullable_Object_as_Float( value );
		}
		else if ( nullable_Object_is_a_Int( value ) )
		{
			native_args[ i ].type = TYPE_INT;
			native_args[ i ].value.i = nullable_Object_as_Int( value );
		}
		else if ( nullable_Object_is_a_Int( value ) )
		{
			native_args[ i ].type = TYPE_BOOL;
			native_args[ i ].value.b = nullable_Object_as_Int( value );
		}
		else if ( nullable_Object_is_a_String( value ) )
		{
			String nit_str = nullable_Object_as_String( value );

			native_args[ i ].type = TYPE_STRING;
			native_args[ i ].value.s = String_to_cstring( nit_str );
		}
		else
		{
			native_args[ i ].type = TYPE_NULL;
			native_args[ i ].value.i = 0;
		}
	}

	*argc_ptr = argc;
	*native_args_ptr = native_args;
}


/*
C implementation of dl::Procedure::call_intern

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
	bigint Array_length( Array recv ) for array::AbstractArrayRead::(abstract_collection::Collection::length)
	nullable_Object Array___bra( Array recv, bigint key ) for array::Array::(abstract_collection::MapRead::[])
	int nullable_Object_is_a_bigint( nullable_Object value ) to check if a nullable Object is a Int
	bigint nullable_Object_as_bigint( nullable_Object value ) to cast from nullable Object to Int
	int nullable_Object_is_a_float( nullable_Object value ) to check if a nullable Object is a Float
	float nullable_Object_as_float( nullable_Object value ) to cast from nullable Object to Float
	int nullable_Object_is_a_int( nullable_Object value ) to check if a nullable Object is a Bool
	int nullable_Object_as_int( nullable_Object value ) to cast from nullable Object to Bool
	int nullable_Object_is_a_String( nullable_Object value ) to check if a nullable Object is a String
	String nullable_Object_as_String( nullable_Object value ) to cast from nullable Object to String
*/
void Procedure_call_intern___impl( Procedure recv, Array args )
{
	NITDL_CALL( ;, void, ;, ; )
}

/*
C implementation of dl::PointerFunction::(dl::Function::call_intern)

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
	bigint Array_length( Array recv ) for array::AbstractArrayRead::(abstract_collection::Collection::length)
	nullable_Object Array___bra( Array recv, bigint key ) for array::Array::(abstract_collection::MapRead::[])
	int nullable_Object_is_a_bigint( nullable_Object value ) to check if a nullable Object is a Int
	bigint nullable_Object_as_bigint( nullable_Object value ) to cast from nullable Object to Int
	int nullable_Object_is_a_float( nullable_Object value ) to check if a nullable Object is a Float
	float nullable_Object_as_float( nullable_Object value ) to cast from nullable Object to Float
	int nullable_Object_is_a_int( nullable_Object value ) to check if a nullable Object is a Bool
	int nullable_Object_as_int( nullable_Object value ) to cast from nullable Object to Bool
	int nullable_Object_is_a_String( nullable_Object value ) to check if a nullable Object is a String
	String nullable_Object_as_String( nullable_Object value ) to cast from nullable Object to String
*/
void * PointerFunction_call_intern___impl( PointerFunction recv, Array args )
{
	NITDL_CALL( void* result, void*, result =, return result )
}

/*
C implementation of dl::FloatFunction::(dl::Function::call_intern)

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
	bigint Array_length( Array recv ) for array::AbstractArrayRead::(abstract_collection::Collection::length)
	nullable_Object Array___bra( Array recv, bigint key ) for array::Array::(abstract_collection::MapRead::[])
	int nullable_Object_is_a_bigint( nullable_Object value ) to check if a nullable Object is a Int
	bigint nullable_Object_as_bigint( nullable_Object value ) to cast from nullable Object to Int
	int nullable_Object_is_a_float( nullable_Object value ) to check if a nullable Object is a Float
	float nullable_Object_as_float( nullable_Object value ) to cast from nullable Object to Float
	int nullable_Object_is_a_int( nullable_Object value ) to check if a nullable Object is a Bool
	int nullable_Object_as_int( nullable_Object value ) to cast from nullable Object to Bool
	int nullable_Object_is_a_String( nullable_Object value ) to check if a nullable Object is a String
	String nullable_Object_as_String( nullable_Object value ) to cast from nullable Object to String
*/
float FloatFunction_call_intern___impl( FloatFunction recv, Array args )
{
	NITDL_CALL( float result, float, result =, return result )
}

/*
C implementation of dl::IntFunction::(dl::Function::call_intern)

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
	bigint Array_length( Array recv ) for array::AbstractArrayRead::(abstract_collection::Collection::length)
	nullable_Object Array___bra( Array recv, bigint key ) for array::Array::(abstract_collection::MapRead::[])
	int nullable_Object_is_a_bigint( nullable_Object value ) to check if a nullable Object is a Int
	bigint nullable_Object_as_bigint( nullable_Object value ) to cast from nullable Object to Int
	int nullable_Object_is_a_float( nullable_Object value ) to check if a nullable Object is a Float
	float nullable_Object_as_float( nullable_Object value ) to cast from nullable Object to Float
	int nullable_Object_is_a_int( nullable_Object value ) to check if a nullable Object is a Bool
	int nullable_Object_as_int( nullable_Object value ) to cast from nullable Object to Bool
	int nullable_Object_is_a_String( nullable_Object value ) to check if a nullable Object is a String
	String nullable_Object_as_String( nullable_Object value ) to cast from nullable Object to String
*/
bigint IntFunction_call_intern___impl( IntFunction recv, Array args )
{
	NITDL_CALL( bigint result, bigint, result =, return result )
}

/*
C implementation of dl::BoolFunction::(dl::Function::call_intern)

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
	bigint Array_length( Array recv ) for array::AbstractArrayRead::(abstract_collection::Collection::length)
	nullable_Object Array___bra( Array recv, bigint key ) for array::Array::(abstract_collection::MapRead::[])
	int nullable_Object_is_a_bigint( nullable_Object value ) to check if a nullable Object is a Int
	bigint nullable_Object_as_bigint( nullable_Object value ) to cast from nullable Object to Int
	int nullable_Object_is_a_float( nullable_Object value ) to check if a nullable Object is a Float
	float nullable_Object_as_float( nullable_Object value ) to cast from nullable Object to Float
	int nullable_Object_is_a_int( nullable_Object value ) to check if a nullable Object is a Bool
	int nullable_Object_as_int( nullable_Object value ) to cast from nullable Object to Bool
	int nullable_Object_is_a_String( nullable_Object value ) to check if a nullable Object is a String
	String nullable_Object_as_String( nullable_Object value ) to cast from nullable Object to String
*/
int BoolFunction_call_intern___impl( BoolFunction recv, Array args )
{
	NITDL_CALL( int result, int, result =, return result )
}

/*
C implementation of dl::StringFunction::(dl::Function::call_intern)

Imported methods signatures:
	String new_String_from_cstring( char * str ) for string::String::from_cstring
	char * String_to_cstring( String recv ) for string::String::to_cstring
	bigint Array_length( Array recv ) for array::AbstractArrayRead::(abstract_collection::Collection::length)
	nullable_Object Array___bra( Array recv, bigint key ) for array::Array::(abstract_collection::MapRead::[])
	int nullable_Object_is_a_bigint( nullable_Object value ) to check if a nullable Object is a Int
	bigint nullable_Object_as_bigint( nullable_Object value ) to cast from nullable Object to Int
	int nullable_Object_is_a_float( nullable_Object value ) to check if a nullable Object is a Float
	float nullable_Object_as_float( nullable_Object value ) to cast from nullable Object to Float
	int nullable_Object_is_a_int( nullable_Object value ) to check if a nullable Object is a Bool
	int nullable_Object_as_int( nullable_Object value ) to cast from nullable Object to Bool
	int nullable_Object_is_a_String( nullable_Object value ) to check if a nullable Object is a String
	String nullable_Object_as_String( nullable_Object value ) to cast from nullable Object to String
*/
String StringFunction_call_intern___impl( StringFunction recv, Array args )
{
	NITDL_CALL( char* result, char*, result =, return new_String_from_cstring( result ) )
}




DynamicLibrary nitdl_dlopen( String name, int flags )
{
	char *native_name = String_to_cstring( name );

	return dlopen( native_name, flags );
}

/*
C implementation of dl::DynamicLibrary::open

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
*/
DynamicLibrary new_DynamicLibrary_open___impl( String name )
{
	return nitdl_dlopen( name, RTLD_LAZY );
}

/*
C implementation of dl::DynamicLibrary::open_now

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
*/
DynamicLibrary new_DynamicLibrary_open_now___impl( String name )
{
	return nitdl_dlopen( name, RTLD_NOW );
}


void* nitdl_dlsym( DynamicLibrary recv, String name )
{
	char *native_name = String_to_cstring( name );
	return dlsym( recv, native_name );
}

/*
C implementation of dl::DynamicLibrary::sym_procedure

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
*/
Procedure DynamicLibrary_sym_procedure___impl( DynamicLibrary recv, String name )
{
	return nitdl_dlsym( recv, name );
}

/*
C implementation of dl::DynamicLibrary::sym_float

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
*/
FloatFunction DynamicLibrary_sym_float___impl( DynamicLibrary recv, String name )
{
	return nitdl_dlsym( recv, name );
}

/*
C implementation of dl::DynamicLibrary::sym_int

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
*/
IntFunction DynamicLibrary_sym_int___impl( DynamicLibrary recv, String name )
{
	return nitdl_dlsym( recv, name );
}

/*
C implementation of dl::DynamicLibrary::sym_bool

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
*/
BoolFunction DynamicLibrary_sym_bool___impl( DynamicLibrary recv, String name )
{
	return nitdl_dlsym( recv, name );
}

/*
C implementation of dl::DynamicLibrary::sym_string

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
*/
StringFunction DynamicLibrary_sym_string___impl( DynamicLibrary recv, String name )
{
	return nitdl_dlsym( recv, name );
}

/*
C implementation of dl::DynamicLibrary::sym_pointer

Imported methods signatures:
	char * String_to_cstring( String recv ) for string::String::to_cstring
*/
PointerFunction DynamicLibrary_sym_pointer___impl( DynamicLibrary recv, String name )
{
	return nitdl_dlsym( recv, name );
}

/*
C implementation of dl::DynamicLibrary::is_loaded
*/
int DynamicLibrary_is_loaded___impl( DynamicLibrary recv )
{
	return recv != NULL;
}

/*
C implementation of dl::DynamicLibrary::error

Imported methods signatures:
	String new_String_from_cstring( char * str ) for string::String::from_cstring
	nullable_String String_as_nullable( String value ) to cast from String to nullable String
*/
nullable_String DynamicLibrary_error___impl( DynamicLibrary recv )
{
	String nit_error;
	char *native_error;

	native_error = dlerror();

	if ( native_error == NULL )
		return null_String();
	else
	{
		nit_error = new_String_from_cstring( native_error );
		return String_as_nullable( nit_error );
	}
}

/*
C implementation of dl::DynamicLibrary::close
*/
void DynamicLibrary_close___impl( DynamicLibrary recv )
{
	dlclose( recv );
}
