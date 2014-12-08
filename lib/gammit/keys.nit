# This file is part of NIT (http://www.nitlanguage.org).
#
# Copyright 2014 Alexis Laferrière <alexis.laf@xymus.net>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	 http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# 
#
# - [ ] SDLKeys
# - [ ] Track mouse/pointer
module keys

import mnit_input

import glesv2_display

redef class GammitDisplay
	var keys = new GammitKeys
end

class GammitKeys
	var downs = new HashSet[String]

	fun [](key: String): Bool
	do
		return downs.has(key)
	end

	fun register(event: InputEvent)
	do
		if event isa KeyEvent then
			var key = event.name
			if event.is_down then
				downs.add key
			else
				downs.remove key
			end
		end
	end
end
