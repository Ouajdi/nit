# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2014 Alexis Laferrière <alexis.laf@xymus.net>
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

extern class CArray[E: Pointer] `{ void** `}
	new malloc(length: Int) `{ return malloc(length * sizeof(void*)); `}
	
	fun [](offset: Int): E `{ return recv[offset]; `}
	fun []=(offset: Int, val: E) `{ recv[offset] = val; `}
end

extern class PInt `{ long* `}
	new (v: Int) `{
		long *p = malloc(sizeof(long));
		(*p) = v;
		return p;
	`}

	redef fun to_s do return to_i.to_s
	private fun to_i: Int `{ return *recv; `}
end

var ints = new CArray[PInt].malloc(2)
ints[0] = new PInt(11111)
ints[1] = new PInt(22222)
print ints[0].to_i
print ints[1].to_i
