# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2008 Floréal Morandat <morandat@lirmm.fr>
# Copyright 2012 Alexis Laferrière <alexis.laf@xymus.net>
#
# This file is free software, which comes along with NIT.  This software is
# distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A
# PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
# is kept unaltered, and a notification of the changes is added.
# You  are  allowed  to  redistribute it and sell it, alone or is a part of
# another product.

# Management of time and dates
package time

import kernel

redef class Object
	# Unix time: the number of seconds elapsed since January 1, 1970
	protected fun get_time: Int is extern "kernel_Any_Any_get_time_0"
end

redef class Int
	# Sleep for a specified amount of time in seconds
	fun sleep is extern

	# Sleep for a specified amount of time in nanoseconds
	fun nanosleep is extern
end
