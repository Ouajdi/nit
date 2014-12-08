
# TODO use numeric safe operations
#
# assert width > 0
# assert height > 0
class Matrix[N: Numeric]
	var width: Int
	var height: Int

	private var items: Array[N] is noinit

	init
	do
		items = new Array[N].filled_with(0.0, width*height)
	end

	#
	init from_array(width, height: Int, array: Array[N])
	do
		init(width, height)

		assert array.length >= width*height

		for i in height.times do
			for j in width.times do
				self[j, i] = array[i + j*width]
			end
		end
	end

	#
	init from(data: Array[Array[N]])
	do
		assert data.length > 0

		init(data.first.length, data.length)

		for j in height.times do
			assert data[j].length == width
		end

		for j in height.times do
			for i in width.times do
				self[j, i] = data[j][i]
			end
		end
	end

	# Get the identity matrix
	#
	# Can only be a `Matrix[Float]`.
	#
	# ~~~
	# var i = new Matrix[Float].identity(3)
	# assert i.to_s == """
	# 1.0 0.0 0.0
	# 0.0 1.0 0.0
	# 0.0 0.0 1.0"""
	# ~~~
	new identity(size: Int)
	do
		var mat = new Matrix[N](size, size)
		assert mat isa Matrix[Float]
		for i in size.times do
			for j in size.times do
				mat[j, i] = if i == j then 1.0 else 0.0
			end
		end
		return mat
	end

	# Get the value at column `x` and row `y`
	#
	# Require: `x >= 0 and x <= width and y >= 0 and y <= height`
	fun [](y, x: Int): N
	do
		assert x >= 0 and x <= width
		assert y >= 0 and y <= height

		return items[x + y*width]
	end

	# Set the `value` at column `x` and row `y`
	#
	# Require: `x >= 0 and x <= width and y >= 0 and y <= height`
	fun []=(y, x: Int, value: N)
	do
		assert x >= 0 and x <= width
		assert y >= 0 and y <= height

		items[x + y*width] = value
	end

	#
	# 
	# Require: `width == other.height`
	#
	# ~~~
	# var m = new Matrix[Float].from([[3.0, 4.0],
	#                                 [5.0, 6.0]])
	# var i = new Matrix[Float].identity(2)
	#
	# assert m * i == m
	# assert m * m.to_s == """
	# 29.0 36.0
	# 45.0 56.0
	# """
	#
	# var a = new Matrix[Float].from([[1.0, 2.0, 3.0],
    #                                 [4.0, 5.0, 6.0]])
	# var b = new Matrix[Float].from([[1.0],
    #                                 [2.0],
    #                                 [3.0]])
	# var c = a * b
	# print c
	# assert c.to_s == """
	# 14.0
	# 32.0"""
	# ~~~
	fun *(other: Matrix[N]): Matrix[N]
	do
		assert self.width == other.height

		var out = new Matrix[N](other.width, self.height)
		for j in self.height.times do
			for i in other.width.times do
				var sum = items.first.zero
				for k in self.width.times do sum += self[j, k] * other[k, i]
				out[j, i] = sum
			end
		end
		return out
	end

	#
	#
	# ~~~
	# var i = new Matrix[Float].identity(3)
	# var rot = new Matrix[Float].rotation(pi, 1.0, 0.0, 0.0)
	# ~~~
	new rotation(angle, x, y, z: Float) 
	do
		var mat = new Matrix[N].identity(4)

		var mag = (x*x + y*y + z*z).sqrt
		var sin = angle.sin
		var cos = angle.cos

		if mag > 0.0 then
			x = x / mag
			y = y / mag
			z = z / mag

			var inv_cos = 1.0 - cos

			mat[0, 0] = inv_cos*x*x + cos
			mat[0, 1] = inv_cos*x*y - z*sin
			mat[0, 2] = inv_cos*z*x + y*sin

			mat[1, 0] = inv_cos*x*y + z*sin
			mat[1, 1] = inv_cos*y*y + cos
			mat[1, 2] = inv_cos*y*z - x*sin

			mat[2, 0] = inv_cos*z*x - y*sin
			mat[2, 1] = inv_cos*y*z + x*sin
			mat[2, 2] = inv_cos*z*z + cos
		end
		return mat
	end

	fun rotate(angle, x, y, z: Float) 
	do
		assert self isa Matrix[Float]

		var rotation = new Matrix[Float].rotation(angle, x, y, z)
		var rotated = self * rotation
		self.items = rotated.items
	end

	fun iterator: MapIterator[MatrixCoordinate, N] do return new MatrixIndexIterator[N](self)

	redef fun to_s
	do
		var lines = new Array[String]
		for y in height.times do
			lines.add items.subarray(y*width, width).join(" ")
		end
		return lines.join("\n")
	end

	redef fun ==(other) do return other isa Matrix[N] and other.items == self.items
	redef fun hash do return items.hash
end

class MatrixIndexIterator[N: Numeric]
	super MapIterator[MatrixCoordinate, N]

	private var matrix: Matrix[N]

	redef var key = new MatrixCoordinate(0, 0)

	redef fun is_ok do return key.y < matrix.height

	redef fun item
	do
		assert is_ok
		return matrix[key.x, key.y]
	end

	redef fun next
	do
		assert is_ok
		var key = key
		if key.x == matrix.width - 1 then
			key.x = 0
			key.y += 1
		else
			key.x += 1
		end
	end
end

#
class MatrixCoordinate
	#
	var x: Int

	#
	var y: Int

	redef fun to_s do return "({x},{y})"
end

#var i = new Matrix[Float].identity(3)
#var rot = new Matrix[Float].rotation(0.25*pi, 0.0, 1.0, 0.0)
#print rot
