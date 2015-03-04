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

module better_generation

import noise

import mineit
import optimized

redef class MineitWorld
	protected var n_trees = 256

	protected var category_size = 48

	redef var speed = 0.2

	redef fun ground_depth do return 8

	redef fun generate(display, app)
	do
		var texture = app.terrain_texture
		var tile_size = app.tile_size

		srand
		var grass_level = new PerlinNoise
		grass_level.min = -ground_depth.to_f
		grass_level.max = -ground_depth.to_f + 32.0
		#grass_level.n_levels = 4
		grass_level.period = 64.0

		var rock_level = new PerlinNoise
		rock_level.min = -ground_depth.to_f
		rock_level.max = -ground_depth.to_f + 16.0
		rock_level.period = 16.0

		var block

		# Ground
		var grass = texture.subtexture(tile_size*0, tile_size*0, tile_size, tile_size)
		var dirt = texture.subtexture(tile_size*2, tile_size*0, tile_size, tile_size)
		var cobble = texture.subtexture(tile_size*1, tile_size*0, tile_size, tile_size)
		var gold = texture.subtexture(tile_size*0, tile_size*2, tile_size, tile_size)
		var coal = texture.subtexture(tile_size*2, tile_size*2, tile_size, tile_size)
		var diamond = texture.subtexture(tile_size*2, tile_size*3, tile_size, tile_size)
		for x in ground_cover do
			for z in ground_cover do
				var grass_y = grass_level[x.to_f, z.to_f].to_i

				var rock_y = rock_level[x.to_f, z.to_f].to_i

				for y in [-ground_depth..grass_y.max(rock_y)] do
					block = new Block(x.to_f, y.to_f, z.to_f)
					block.category = x/category_size + 1024*z/category_size
					if y <= rock_y then
						var r = 20.rand
						if r == 0 then
							block.texture = gold
						else if r == 1 then
							block.texture = coal
						else if r == 2 then
							block.texture = diamond
						else
							block.texture = cobble
						end
					else if y == grass_y then
						block.texture = grass
						block.color = new Color.green
						block.side_texture = dirt # grass_side
					else
						block.texture = dirt
					end
					app.add block
				end
			end
		end

		# Tree
		var leaves = texture.subtexture(tile_size*4, tile_size*3, tile_size, tile_size)
		var trunk = texture.subtexture(tile_size*4, tile_size*1, tile_size, tile_size)

		# Place trees
		for t in n_trees.times do

			var dx = ground_cover.rand.to_f
			var dz = ground_cover.rand.to_f
			var dy = grass_level[dx.to_f, dz.to_f].floor+1.0

			# Leaves
			for x in [-2..2] do
				for y in [-2..2] do
					for z in [-2..2] do
						# Cut off all corners
						if [x.abs, z.abs, y.abs].count(2) >= 2 then continue

						block = new Block(x.to_f+dx, 5.0+y.to_f+dy, z.to_f+dz)
						block.color = new Color.green
						block.texture = leaves
						block.is_opaque = false
						app.add block
					end
				end
			end

			# Trunk
			for y in [0..2] do
				block = new Block(dx, dy+y.to_f, dz)
				block.texture = trunk
				app.add block
			end
		end

		app.consolidate_visibles
	end
end

redef class GammitApp
	redef fun add(e)
	do
		# Check if there is already a block
		var prev = world.blocks[e.x, e.y, e.z]
		if prev != null then return

		super
	end
end
