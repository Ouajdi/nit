# A color
#
# * `bright_*` 1.0, 0, 0
# * `*` 0.66, 0, 0
# * `dark_*` 0.33, 0, 0
# * `light_*` 1.0, 0.33, 0.33
# * `pastel_*` 1.0, 0.66, 0.66
# * `neutral_*` 0.66, 0.33, 0.33
class Color
	var r: Float
	var g: Float
	var b: Float
	var a = 1.0 is writable

	init rand do set(1.0.rand, 1.0.rand, 1.0.rand)

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
	end

	redef fun hash do return (r*255.0).to_i * 0x01ffff + (g*255.0).to_i * 0x01ff + (b*255.0).to_i
	redef fun ==(o) do return o isa Color and o.r == r and o.g == g and o.b == b
	redef fun to_s do return "#{(r*255.0).to_i.to_hex}{(g*255.0).to_i.to_hex}{(b*255.0).to_i.to_hex}"

	#
	fun to_a: Array[Float] do return [r, g, b, a]
end
