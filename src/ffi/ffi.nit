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

# provides ffi functionalities
module ffi

import c

redef class MMSrcModule
	redef fun compile_separate_module(cprogram: CProgram)
	do
		super

		if is_extern_hybrid then
			var visitor = new FFIVisitor( cprogram.program.tc, self )
			# TODO use cprogram to add generated files?

			# actually compile stub
			accept_ffi_visitor( visitor )

			# write to file
			if uses_ffi then
				visitor.compile( cprogram )
			end
		end
	end
end
