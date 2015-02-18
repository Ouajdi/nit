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

# A rectangular array of `Numeric`
#
# Require: width > 0
# Require: height > 0
class Matrix[N: Numeric]

	# Number of columns
	var width: Int

	# Number of rows
	var height: Int

	# Items of this matrix, rows by rows
	private var items: Array[N] is lazy	do
		var items = new Array[N]

		# Ugly hack to get 0 in the domain of N
		var zero: N
		if items isa Array[Int] then
			zero = 0
		else
			# Is either a Float or a general Numeric
			zero = 0.0
		end

		return [zero]*(width*height)
	end

	# Create a matrix from an `Array[Array[N]]`
	#
	# Require: `not items.is_empty`
	# Require: all rows are of the same length
	#
	# ~~~
	# var array = [[1.0, 2.0],
	#              [3.0, 4.0]]
	# var matrix = new Matrix[Float].from(array)
	# assert matrix.to_s == """
	# 1.0 2.0
	# 3.0 4.0"""
	# ~~~
	init from(items: Array[Array[N]])
	do
		assert not items.is_empty

		init(items.first.length, items.length)

		for j in height.times do assert items[j].length == width

		for j in height.times do
			for i in width.times do
				self[j, i] = items[j][i]
			end
		end
	end

	# Create a matrix from an `Array[N]` composed of rows after rows
	#
	# Require: `width > 0 and height > 0`
	# Require: `array.length >= width*height`
	#
	# ~~~
	# var array = [1.0, 2.0,
	#              3.0, 4.0]
	# var matrix = new Matrix[Float].from_array(array)
	# assert matrix.to_s == """
	# 1.0 2.0
	# 3.0 4.0"""
	# ~~~
	init from_array(width, height: Int, array: Array[N])
	do
		assert width > 0
		assert height > 0
		assert array.length >= width*height

		init(width, height)

		for i in height.times do
			for j in width.times do
				self[j, i] = array[i + j*width]
			end
		end
	end

	# Create an identity matrix
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
		var matrix = new Matrix[N](size, size)

		# Not so ugly hack to get 0 and 1 in the domain of N
		var ref = matrix[0, 0]
		var zero = ref.zero
		var one = ref.zero.add(1)

		for i in size.times do
			for j in size.times do
				matrix[j, i] = if i == j then one else zero
			end
		end
		return matrix
	end

	# Create a new copy of this matrix
	fun copy: Matrix[N]
	do
		return new Matrix[N].from_array(width, height, items)
	end

	# Get the value at row `x` and column `y`
	#
	# Require: `x >= 0 and x <= width and y >= 0 and y <= height`
	fun [](y, x: Int): N
	do
		assert x >= 0 and x <= width
		assert y >= 0 and y <= height

		return items[x + y*width]
	end

	# Set the `value` at row `y` and column `x`
	#
	# Require: `x >= 0 and x <= width and y >= 0 and y <= height`
	fun []=(y, x: Int, value: N)
	do
		assert x >= 0 and x <= width
		assert y >= 0 and y <= height

		items[x + y*width] = value
	end

	# Matrix product
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

	# Iterate over the values in this matrix
	fun iterator: MapIterator[MatrixCoordinate, N]
	do
		return new MatrixIndexIterator[N](self)
	end

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

private class MatrixIndexIterator[N: Numeric]
	super MapIterator[MatrixCoordinate, N]

	var matrix: Matrix[N]

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

# Position key when iterating over the values of a matrix
class MatrixCoordinate
	# Index of the current column
	var x: Int

	# Index of the current row
	var y: Int

	redef fun to_s do return "({x},{y})"
end
