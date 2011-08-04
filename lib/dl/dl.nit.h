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

#ifndef dl_IMPL_NIT_H
#define dl_IMPL_NIT_H

/* to avoid the "conversion of object pointer to function pointer" warning*/
typedef union { void* ptr; void (*func)(); } nitdl_func_ptr_converter;

#define Callable void*
#define Procedure void*
#define Function void*
#define PointerFunction void*
#define FloatFunction void*
#define IntFunction void*
#define BoolFunction void*
#define StringFunction void*
#define DynamicLibrary void*

#include <dl._nitni.h>

void Procedure_call_intern___impl( Procedure recv, Array args );
void * PointerFunction_call_intern___impl( PointerFunction recv, Array args );
float FloatFunction_call_intern___impl( FloatFunction recv, Array args );
bigint IntFunction_call_intern___impl( IntFunction recv, Array args );
int BoolFunction_call_intern___impl( BoolFunction recv, Array args );
String StringFunction_call_intern___impl( StringFunction recv, Array args );
DynamicLibrary new_DynamicLibrary_open___impl( String name );
DynamicLibrary new_DynamicLibrary_open_now___impl( String name );
Procedure DynamicLibrary_sym_procedure___impl( DynamicLibrary recv, String name );
FloatFunction DynamicLibrary_sym_float___impl( DynamicLibrary recv, String name );
IntFunction DynamicLibrary_sym_int___impl( DynamicLibrary recv, String name );
BoolFunction DynamicLibrary_sym_bool___impl( DynamicLibrary recv, String name );
StringFunction DynamicLibrary_sym_string___impl( DynamicLibrary recv, String name );
PointerFunction DynamicLibrary_sym_pointer___impl( DynamicLibrary recv, String name );
int DynamicLibrary_is_loaded___impl( DynamicLibrary recv );
nullable_String DynamicLibrary_error___impl( DynamicLibrary recv );
void DynamicLibrary_close___impl( DynamicLibrary recv );

#endif
