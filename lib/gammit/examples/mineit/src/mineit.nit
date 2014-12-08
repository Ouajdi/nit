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

# Tolerated bug: Falling into a block may circumvent the collision detection.
module mineit

import gammit::standalone
import gammit::perf_stats
import more_collections
intrude import gammit::glesv2_display

# A visible block in game
class Block
	super VisibleCube
	super Selectable

	redef var x: Float
	redef var y: Float
	redef var z: Float

	var is_opaque = true is writable

	init
	do
		# Reduce the scale ever so slightly that it doesn't overlap its neighbors
		scale = 0.9999
	end
end

# A UI 2D element
class UIElement
	super VisibleSquare

	redef var x: Float
	redef var y: Float
	redef var z: Float
end

# A Mineit world, mostly make of `blocks`
class MineitWorld
	# Blocks in this world
	var blocks = new HashMap3[Float, Float, Float, Block]

	# Dimensions of the floating island
	var ground_cover: Range[Int] = [-7..7]

	# Depth of the floating island
	var ground_depth = 8

	# Player/camera speed
	var speed = 0.05

	# Speed when falling (there's no acceleration for simplicity purpose)
	var falling_speed = 0.3

	# Reachable range of actions
	var action_reach: Float = 5.0

	# Generate the default world
	fun generate(display: GammitDisplay, app: GammitApp)
	do
		var texture = app.texture
		var tile_size = app.tile_size

		# Rock brick
		for h in 3.times do
			var block = new Block(0.0, -1.0+h.to_f, 0.0)
			block.texture = texture.subtexture(tile_size*0, tile_size*1, tile_size, tile_size)
			app.add block
		end

		# glass (ish)
		var block = new Block(1.0, 0.0, 0.0)
		block.texture = texture.subtexture(tile_size*9, tile_size*2, tile_size, tile_size)
		app.add block

		# Gold top
		block = new Block(0.0, 2.0, 0.0)
		block.texture = texture.subtexture(tile_size*7, tile_size*1, tile_size, tile_size)
		block.scale = 0.9
		block.is_opaque = false
		app.add block

		# planks
		block = new Block(1.0, -1.0, 0.0)
		block.texture = texture.subtexture(tile_size*4, tile_size*0, tile_size, tile_size)
		block.is_opaque = false
		app.add block

		# diamond
		block = new Block(1.0, 0.0, 1.0)
		block.texture = texture.subtexture(tile_size*0, tile_size*9, tile_size, tile_size)
		app.add block

		# Some box
		block = new Block(1.0, -1.0, 1.0)
		block.texture = texture.subtexture(tile_size*4, tile_size*5, tile_size, tile_size)
		app.add block

		# Ground
		var grass = texture.subtexture(tile_size*0, tile_size*0, tile_size, tile_size)
		var dirt = texture.subtexture(tile_size*2, tile_size*0, tile_size, tile_size)
		var cobble = texture.subtexture(tile_size*1, tile_size*0, tile_size, tile_size)
		var gold = texture.subtexture(tile_size*0, tile_size*2, tile_size, tile_size)
		var coal = texture.subtexture(tile_size*2, tile_size*2, tile_size, tile_size)
		var diamond = texture.subtexture(tile_size*2, tile_size*3, tile_size, tile_size)
		for x in ground_cover do
			for z in ground_cover do
				for y in [0..ground_depth] do
					block = new Block(x.to_f, -2.0-y.to_f, z.to_f)
					if y == 0 then
						block.texture = grass
						block.color = new Color.green
					else if y > 4 then
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
		for x in [0..2] do
			for y in [0..2] do
				for z in [0..2] do
					block = new Block(3.0+x.to_f, 2.0+y.to_f, -3.0-z.to_f)
					block.color = new Color.green
					block.texture = leaves
					block.is_opaque = false
					app.add block
				end
			end
		end
		for y in [-1..1] do
			block = new Block(4.0, y.to_f, -4.0)
			block.texture = trunk
			app.add block
		end
	end

	fun collision_range: Float do return 0.2

	# Get the block, if any, in a square around `fx`, `fy` and `fz`
	#
	# It will first test the center position, then it will look at 4 corners
	# around it.
	fun block_within(fx, fy, fz: Float): nullable Block
	do
		var y = fy.round

		var block = blocks[fx.round, y, fz.round]
		if block != null then return block

		# Try corners
		var range = collision_range
		for x in [(fx+range).round, (fx-range).round] do
			for z in [(fz+range).round, (fz-range).round] do
				block = blocks[x, y, z]
				if block != null then return block
			end
		end

		return null
	end
end

redef class GammitApp
	# Mineit world
	var world: MineitWorld is writable

	# Main terrain texture
	var texture: GammitGLTexture

	# Dimension of a tile in `texture`
	var tile_size: Int

	# Texture of the block that may be placed with `place`
	var placable_tile: Texture = texture.subtexture(tile_size*4, tile_size*0, tile_size, tile_size) is lazy

	# Camera which also act as the player location
	var camera: SimpleCamera is lazy do
		var camera = new SimpleCamera(display.as(not null))
		camera.position = new Point3d[Float](2.0, 0.0, -1.0)
		return camera
	end

	redef fun setup
	do
		var display = new GammitDisplay(1920, 1200)
		self.display = display

		# You might want to grap all inputs too, but it will also grabs alt-tab
		#display.sdl_display.grab_input = true

		show_splash_screen

		# Load the main texture
		texture = display.load_texture_from_assets("terrain.png")
		tile_size = 16

		world = new MineitWorld
		world.generate(display, self)

		display.background_color = new Color(0.0, 157.0/255.0, 249.0/255.0, 1.0)
		display.lock_cursor = true
		display.show_cursor = false

		setup_ui
		setup_decor
	end

	fun setup_decor
	do
		# Sun (no texture, color only)
		var block = new Block(-100.0, 30.0, 0.0)
		block.color = new Color.yellow
		block.scale = 10.0
		display.add block

		block = new Block(-100.0, 30.0, 0.0) # HACK
		block.color = new Color.yellow
		block.color.a = 0.3
		block.scale = 15.0
		display.add block
	end

	#
	fun show_splash_screen
	do
		var splash = new UIElement(0.0, 0.0, 0.0)
		splash.texture = display.load_texture_from_assets("splash.png")
		splash.program = display.ui_program
		splash.scale = 2.0

		display.add splash
		display.ui_program.mvp_matrix = new Matrix[Float].orthogonal(-1.0, 1.0, 1.0, -1.0, -1.0, 1.0)
		display.draw_all_the_things
		display.remove splash
	end

	# Setup the UI elements
	fun setup_ui
	do
		display.ui_program.mvp_matrix = new Matrix[Float].orthogonal(-1.0*display.aspect_ratio, 1.0*display.aspect_ratio, 1.0, -1.0, -1.0, 1.0)
		# Add a crosshair at the center of the screen
		var crosshair = new UIElement(0.0, 0.0, 0.0)
		crosshair.texture = display.load_texture_from_assets("crosshair.png")
		crosshair.scale = 0.1
		crosshair.program = display.ui_program
		display.add crosshair
	end

	redef fun frame_logic
	do
		var stat_clock = new Clock
		var frame_clock = new Clock

		# Set aside the current position to revert to it on collision
		var last_position = camera.position.copy

		# Inputs
		for key in display.keys.downs do
			if key == "w" then
				camera.move(0.0, 0.0, world.speed)
			else if key == "s" then
				camera.move(0.0, 0.0, -world.speed)
			else if key == "a" then
				camera.move(-world.speed, 0.0, 0.0)
			else if key == "d" then
				camera.move(world.speed, 0.0, 0.0)
			end
		end
		sys.time_stats["inputs"].add stat_clock.lapse

		# Collision detection
		detect_collision last_position
		sys.time_stats["collision"].add stat_clock.lapse

		# Calculate the camera matrix
		display.projection_matrix = camera.mvp_matrix
		sys.time_stats["matrix"].add stat_clock.lapse

		# Draw to screen
		#display.draw_all_the_things
		#sys.time_stats["drawing"].add stat_clock.lapse

		sys.time_stats["frame_logic"].add frame_clock.lapse
		display.selection_camera = camera.position
	end

	# Detect and react to collisions between the `camera` and the `world.blocks`
	#
	# Will revert to `last_position` if there is a collision.
	fun detect_collision(last_position: Point3d[Float])
	do
		# Detect collision, fall and jumps
		var x = camera.position.x
		var y = camera.position.y
		var z = camera.position.z

		var block_over = world.block_within(x, y+1.0, z)
		var block_head = world.block_within(x, y, z)
		var block_feet = world.block_within(x, y-1.0, z)
		var block_under = world.block_within(x, y-2.0, z)

		if block_head != null then
			# Head blocked, cancel
			camera.position = last_position
		else if block_feet != null then
			if block_over != null then
				# Block over head, cannot go up, cancel
				camera.position = last_position
			else
				camera.position.y += 1.0
			end
		else if block_under != null then
			var ty = block_under.y + 2.0
			if camera.position.y > ty then
				# Fall
				camera.position.y = ty.max(camera.position.y - world.falling_speed)
			end
		else if camera.position.y < -40.0 then
			# Falling out of the world, reset player/camera position
			camera.position = new Point3d[Float](2.0, 0.0, -1.0)
		else # block == null
			# Nothing under the player, fall!
			camera.position.y -= world.falling_speed
		end
	end

	# Act on block visible at `x, y` on screen
	#
	# If `mine` break block, otherwise place a new block on top of selected.
	fun act(x, y: Int, mine: Bool)
	do
		# HACK
		display.selection_camera = camera.position
		var selected = display.visible_at(x, y)
		if selected != null and display.visibles.has(selected) then

			# Is it in action range?
			var d2 = (selected.x - camera.position.x).to_f.pow(2.0) +
				(selected.y - camera.position.y).to_f.pow(2.0) +
				(selected.z - camera.position.z).to_f.pow(2.0)
			if d2.sqrt > world.action_reach then return

			var sx = selected.x.to_f
			var sy = selected.y.to_f
			var sz = selected.z.to_f

			print "{sx} {sy} {sz}"

			if mine then
				# Mine block
				if selected isa Block then
					self.mine selected
				end
			else
				# Is the spot above `selected` empty?
				var occupant = world.blocks[sx, sy+1.0, sz]
				if occupant != null then return

				# Place a new block!
				var block = new Block(sx, sy+1.0, sz)
				place block
			end
		end
	end

	# Mine `block` and remove it from `world`
	fun mine(block: Block) do remove block

	# Place `block` in `world`
	fun place(block: Block)
	do
		block.texture = placable_tile
		add block
	end

	redef fun accept_event(event)
	do
		if event isa QuitEvent then
			quit
		else if event isa KeyEvent then
			display.keys.register event # HACK
			if event.name == "q" and event.is_down then
				quit
			end
		end

		return super
	end

	# Quit the game
	fun quit
	do
		print sys.time_stats
		exit 0
	end

	# Add a block to the `world` and the `display`
	fun add(e: Block)
	do
		display.add e
		world.blocks[e.x, e.y, e.z] = e
	end

	# Remove a block from the `world` and the `display`
	fun remove(e: Block)
	do
		display.remove e
		world.blocks.remove_at(e.x, e.y, e.z)
	end
end
