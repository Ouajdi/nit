/* This file is part of NIT ( http://www.nitlanguage.org ).
 *
 * Copyright 2012 Alexis Laferrière <alexis.laf@xymus.net>
 *
 * This file is free software, which comes along with NIT.  This software is
 * distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A
 * PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
 * is kept unaltered, and a notification of the changes is added.
 * You  are  allowed  to  redistribute it and sell it, alone or is a part of
 * another product.
 */

#include "time_nit.h"

#ifdef _POSIX_C_SOURCE
	#undef _POSIX_C_SOURCE
#endif
#define _POSIX_C_SOURCE 199309L
#include <time.h>

#include <unistd.h>

void Int_sleep___impl( bigint recv )
{
	sleep( recv );
}

void Int_nanosleep___impl( bigint recv )
{
	struct timespec req = {recv/1000000000L,recv%1000000000L};
	nanosleep( &req, NULL );
}

