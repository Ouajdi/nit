# This file is part of NIT (http://www.nitlanguage.org).
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
module persistent_binary

import binary

import mineit
intrude import optimized

private fun save_file_path: Path do return once "save.mineit".to_path

redef class MineitWorld
	super BinaryWritable

	fun write_to_binary(stream: BinaryWriter)
	do
		stream.write_binary block_list.length

		for block in block_list do
			stream.write_binary block.x
			stream.write_binary block.y
			stream.write_binary block.z

			var texture = block.texture
			assert texture isa Subtexture
			stream.write_binary texture.source_left
			stream.write_binary texture.source_top
			stream.write_binary texture.source_right
			stream.write_binary texture.source_bottom

			stream.write_binary block.color.r
			stream.write_binary block.color.g
			stream.write_binary block.color.b
			stream.write_binary block.color.a
		end
	end
end

redef class SimpleCamera
	fun write_to_binary(stream: BinaryWriter)
	do
		stream.write_binary position.x
		stream.write_binary position.y
		stream.write_binary position.z
		stream.write_binary pitch
		stream.write_binary yaw
	end

	fun update_from_binary(stream: BinaryReader)
	do
		self.position.x = stream.read_float
		self.position.y = stream.read_float
		self.position.z = stream.read_float
		self.pitch = stream.read_float
		self.yaw = stream.read_float
	end
end

redef class GammitApp

	private fun save
	do
		var s = save_file_path.open_wo
		s.write to_json
		s.close
	end

	#
	fun write_to_binary(stream: BinaryWriter)
	do
		stream.write_binary wold
		stream.write_binary camera
	end

	private fun load: Bool
	do
		if not save_file_path.exists then return false

		var content = save_file_path.read_all
		return load_from_json(content)
	end

	fun load_from_json(content: String): Bool
	do
		print "-------------0"
		var json = content.to_json_value
		print "-------------1"

		if json.is_error then
			print json.to_error
			return false
		end

		# Clean old world
		world = new MineitWorld
		print "-------------a"
		setup_ui
		print "-------------b"

		self.update_world_from_json json["world"]
		self.camera.update_from_json json["camera"]

		return true
	end

	fun update_world_from_binary(stream: BinaryReader)
	do
		consolidated = false
		display.visibles.clear

		var n_blocks = stream.read_int

		for n in n_blocks.times do
			var x = stream.read_float
			var y = stream.read_float
			var z = stream.read_float

			var tl = stream.read_float
			var tt = stream.read_float
			var tr = stream.read_float
			var tb = stream.read_float

			var cr = stream.read_float
			var cg = stream.read_float
			var cb = stream.read_float
			var ca = stream.read_float

			var block = new Block(x, y, z)
			add block

			block.texture = texture.subtexture_by_sides(tl, tt, tr, tb)

			block.color = new Color(cr, cg, cb)
			block.color.a = ca
		end

		consolidate_visibles
	end

	#
	redef fun accept_event(event)
	do
		if event isa KeyEvent and event.is_down then
			display.keys.register event # HACK
			if event.name == "k" then
				# Save
				save
				return true
			else if event.name == "l" then
				# Load
				if not load then print "Loading failed"
				return true
			end
		end

		return super
	end
end

redef universal Float
	# Use a higher precision when saving floats
	fun to_json: String
	do
		#if self % 1.0 == 0.0 then return to_i.to_s
		var str = to_precision(6)
		var e = str.length - 1

		while e > 0 and str.chars[e] == '0' do e -= 1

		return str.substring(0, e)
	end
end

redef class Array[E]
	#
	fun to_json: String do return "[{join(",")}]"
end
