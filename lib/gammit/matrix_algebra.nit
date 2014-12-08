
import matrix

import glesv2

redef class Matrix[N]
	# Get an orthogonal projection matrix
	new orthogonal(left, right, bottom, top, near, far: Float)
	do
		var dx = right - left
		var dy = top - bottom
		var dz = far - near

		assert dx != 0.0 and dy != 0.0 and dz != 0.0

		var mat = new Matrix[N].identity(4)
		assert mat isa Matrix[Float]

		mat[0, 0] = 2.0 / dx
		mat[3, 0] = -(right + left) / dx
		mat[1, 1] = 2.0 / dy
		mat[3, 1] = -(top + bottom) / dy
		mat[2, 2] = 2.0 / dz
		mat[3, 2] = -(near + far) / dz
		return mat
	end

	#
	new perspective(field_of_view_y, aspect_ratio, near, far: Float)
	do
		var frustum_height = (field_of_view_y/2.0).tan * near
		var frustum_width = frustum_height * aspect_ratio

		return new Matrix[N].frustum(-frustum_width, frustum_width, -frustum_height, frustum_height, near, far)
	end

	#
	new frustum(left, right, bottom, top, near, far: Float)
	do
		# TODO check order of args, ex: assert left > right
		var dx = right - left
		var dy = top - bottom
		var dz = far - near

		assert near > 0.0
		assert far > 0.0
		assert dx > 0.0
		assert dy > 0.0
		assert dz > 0.0

		var mat = new Matrix[N](4, 4)
		assert mat isa Matrix[Float]

		mat[0, 0] = 2.0 * near / dx
		mat[0, 1] = 0.0
		mat[0, 2] = 0.0
		mat[0, 3] = 0.0

		mat[1, 0] = 0.0
		mat[1, 1] = 2.0 * near / dy
		mat[1, 2] = 0.0
		mat[1, 3] = 0.0

		mat[2, 0] = (right + left) / dx
		mat[2, 1] = (top + bottom) / dy
		mat[2, 2] = -(near + far) / dz
		mat[2, 3] = -1.0

		mat[3, 0] = 0.0
		mat[3, 1] = 0.0
		mat[3, 2] = -2.0 * near * far / dz
		mat[3, 3] = 0.0

		return mat
	end

	#
	fun translate(dx, dy, dz: Float)
	do
		assert self isa Matrix[Float]

		for i in [0..3] do
			self[3, i] += self[0, i]*dx + self[1, i]*dy + self[2, i]*dz
		end
	end

	fun scale(x, y, z: Float)
	do
		assert self isa Matrix[Float]

		for i in [0..3] do
			self[0, i] = self[0, i] * x
			self[1, i] = self[1, i] * y
			self[2, i] = self[2, i] * z
		end
	end
end
