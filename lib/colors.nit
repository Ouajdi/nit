# This file is part of NIT ( http://www.nitlanguage.org ).
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

# A color
#
# * `bright_*` 1.0, 0, 0
# * `*` 0.66, 0, 0
# * `dark_*` 0.33, 0, 0
# * `light_*` 1.0, 0.33, 0.33
# * `pastel_*` 1.0, 0.66, 0.66
# * `neutral_*` 0.66, 0.33, 0.33
class Color
	var r: Float is writable
	var g: Float is writable
	var b: Float is writable
	var a: Float is writable

	init rand do set(1.0.rand, 1.0.rand, 1.0.rand)

	init from_bytes(r, g, b, a: Int) do init(a.to_f/255.0, a.to_f/255.0, a.to_f/255.0, a.to_f/255.0)

	# Get a color from an hexadecimal string
	#
	# Applies simple heuristics to detect different color format:
	# * "FF0000" creates red
	# * "ffffff" creates white
	# * "0000ff77" creates a half transparent blue
	# * "7f7" creates a light blue
	# * "7f7b" creates a light blue almost fully opaque
	#
	# Require: `hex_value.length >= 3 and hex_value.length != 5`
	init from_hex(hex_value: String)
	do
		var length = hex_value.length
		var r = 0.0
		var g = 0.0
		var b = 0.0
		var a = 1.0

		if length >= 6 then
			var sr = hex_value.substring(0, 2)
			var sg = hex_value.substring(2, 2)
			var sb = hex_value.substring(4, 2)

			if sr.is_hex then r = sr.to_hex.to_f / 255.0
			if sg.is_hex then g = sg.to_hex.to_f / 255.0
			if sb.is_hex then b = sb.to_hex.to_f / 255.0

			if length >= 8 then
				var sa = hex_value.substring(6, 2)
				if sa.is_hex then a = sa.to_hex.to_f / 255.0
			end
		else if length == 3 or length == 4 then
			var sr = hex_value.substring(0, 1)
			var sg = hex_value.substring(1, 1)
			var sb = hex_value.substring(2, 1)

			if sr.is_hex then r = sr.to_hex.to_f / 15.0
			if sg.is_hex then g = sg.to_hex.to_f / 15.0
			if sb.is_hex then b = sb.to_hex.to_f / 15.0

			if length == 4 then
				var sa = hex_value.substring(3, 1)
				if sa.is_hex then a = sa.to_hex.to_f / 15.0
			end
		else abort

		init(r, g, b, a)
	end

	init white do set(1, 1, 1)
	init light_gray do set(0.66, 0.66, 0.66)
	init dark_gray do set(0.33, 0.33, 0.33)
	init black do set(0, 0, 0)

	init bright_red do set(1, 0, 0)
	init bright_green do set(0, 1, 0)
	init bright_blue do set(0, 0, 1)
	init bright_yellow do set(1, 1, 0)
	init bright_cyan do set(0, 1, 1)
	init bright_magenta do set(1, 0, 1)

	init gray do set(0.66, 0.66, 0.66)
	init red do set(0.66, 0, 0)
	init green do set(0, 0.66, 0)
	init blue do set(0, 0, 0.66)
	init yellow do set(0.66, 0.66, 0)
	init cyan do set(0, 0.66, 0.66)
	init magenta do set(0.66, 0, 0.66)

	init dark_red do set(0.33, 0, 0)
	init dark_green do set(0, 0.33, 0)
	init dark_blue do set(0, 0, 0.33)
	init dark_yellow do set(0.33, 0.33, 0)
	init dark_cyan do set(0, 0.33, 0.33)
	init dark_magenta do set(0.33, 0, 0.33)

	init light_red do set(1, 0.33, 0.33)
	init light_green do set(0.33, 1, 0.33)
	init light_blue do set(0.33, 0.33, 1)
	init light_yellow do set(1, 1, 0.33)
	init light_cyan do set(0.33, 1, 1)
	init light_magenta do set(1, 0.33, 1)

	init pastel_red do set(1, 0.66, 0.66)
	init pastel_green do set(0.66, 1, 0.66)
	init pastel_blue do set(0.66, 0.66, 1)
	init pastel_yellow do set(1, 1, 0.66)
	init pastel_cyan do set(0.66, 1, 1)
	init pastel_magenta do set(1, 0.66, 1)

	init neutral_red do set(0.66, 0.33, 0.33)
	init neutral_green do set(0.33, 0.66, 0.33)
	init neutral_blue do set(0.33, 0.33, 0.66)
	init neutral_yellow do set(0.66, 0.66, 0.33)
	init neutral_cyan do set(0.33, 0.66, 0.66)
	init neutral_magenta do set(0.66, 0.33, 0.66)

	private fun set(r, g, b: Numeric)
	do
		self.r = r.to_f
		self.g = g.to_f
		self.b = b.to_f
		self.a = 1.0
	end

	redef fun hash do return (r*255.0).to_i * 0x01ffff + (g*255.0).to_i * 0x01ff + (b*255.0).to_i
	redef fun ==(o) do return o isa Color and o.r == r and o.g == g and o.b == b
	redef fun to_s do return "#{(r*255.0).to_i.to_hex}{(g*255.0).to_i.to_hex}{(b*255.0).to_i.to_hex}"

	#
	fun to_a: Array[Float] do return [r, g, b, a]
end
