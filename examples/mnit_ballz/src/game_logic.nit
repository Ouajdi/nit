#this file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2014 Romain Chanoir <romain.chanoir@viacesi.fr>
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

module game_logic

import mnit_android
import android::sensors
import android::audio
import android::assets_and_resources
import geometry

class Ball
	var x: Float
	var y: Float
	var dim: Int
	var walls_activated: Bool
	var offset_x = 0.0
	var offset_y = 0.0
	var going_left: Bool
	var going_down: Bool

	var game: Game
	var screen: Screen

	init(game: Game, x,y: Float, walls: Bool, screen: Screen)
	do
		self.x = x
		self.y = y
		self.dim = 20
		self.game = game
		self.walls_activated = walls
		self.screen = screen
	end

	# not very useful at this time
	fun do_turn
	do
	end

	fun intercepts(event: InputEvent): Bool
	do
		if event isa ASensorAccelerometer then
			do_move(event)
		else if event isa ASensorMagneticField then
			#deal with Magnetic field sensor
			#print "ASensorMagneticField : x = " + event.x.to_s + " y = " + event.y.to_s + " z = " + event.z.to_s
		else if event isa ASensorGyroscope then
			#deal with Gyroscope sensor
			#print "ASensorGyroscope : x = " + event.x.to_s + " y = " + event.y.to_s + " z = " + event.z.to_s
		else if event isa ASensorLight then
			#deal with light sensor
			#print "ASensorLight : light = " + event.light.to_s
		else if event isa ASensorProximity then
			#deal with proximity sensor
			#print "ASensorProximity : distance = " + event.distance.to_s
		else if event isa MotionEvent then
			activate_walls(event)
		end
		return true
	end

	fun do_move (event: ASensorAccelerometer)
	do
		# acceleration value
		var vx = event.x
		var vy = event.y

		var gw = game.width - game.config.ball_radius*screen.ball_img.scale
		var gh = game.height - game.config.ball_radius*screen.ball_img.scale

		# acceleration
		var max_value = 9.80
		var acceleration_x = vx/max_value
		var acceleration_y = vy/max_value
		offset_x -= (acceleration_x/10.0)*(vx.abs) + offset_x/125.0
		offset_y += (acceleration_y/10.0)*(vy.abs) - offset_y/125.0
		var nx = self.x + offset_x
		var ny = self.y + offset_y
		going_left = offset_x > 0.0
		going_down = offset_y > 0.0

		#  intersection test
		var ballbox: Box[Float]
		if self.x < nx then
			if self.y < ny then
				ballbox = new Box[Float].lrbt(self.x - game.config.ball_radius*screen.ball_img.scale, nx + game.config.ball_radius*screen.ball_img.scale,
					self.y- game.config.ball_radius*screen.ball_img.scale, ny + game.config.ball_radius*screen.ball_img.scale)
			else 
				ballbox = new Box[Float].lrbt(self.x- game.config.ball_radius*screen.ball_img.scale, nx + game.config.ball_radius*screen.ball_img.scale,
					ny + game.config.ball_radius*screen.ball_img.scale, self.y + game.config.ball_radius*screen.ball_img.scale)
			end
		else
			if self.y < ny then
				ballbox = new Box[Float].lrbt(nx - game.config.ball_radius*screen.ball_img.scale, self.x + game.config.ball_radius*screen.ball_img.scale,
					self.y- game.config.ball_radius*screen.ball_img.scale, ny + game.config.ball_radius*screen.ball_img.scale)
			else
				ballbox = new Box[Float].lrbt(nx - game.config.ball_radius*screen.ball_img.scale, self.x + game.config.ball_radius*screen.ball_img.scale,
					ny + game.config.ball_radius*screen.ball_img.scale, self.y + game.config.ball_radius*screen.ball_img.scale)
			end
		end

		# walls gestion
		var wall_to_del: nullable Wall
		wall_to_del = null
		for w in game.walls do
				if ballbox.intersects(w) then wall_to_del = w
		end
		
		if wall_to_del != null then 
			game.walls.remove(wall_to_del)
			# game.walld_sound.play
		end

		# values of the screen bordure counting the ball radius
		var relative_zero = 0.0 + game.config.ball_radius*screen.ball_img.scale

		# x value
		if nx >= relative_zero and nx <= gw then
			self.x = nx
		else if nx < relative_zero then
			if not walls_activated then self.x = gw else do_bounce(1)
		else if nx > gw then
			if not walls_activated then self.x = relative_zero else do_bounce(1)
		end

		# y value
		if ny >= relative_zero and ny <= gh then
			self.y = ny
		else if ny < relative_zero then
			if not walls_activated then self.y = gh else do_bounce(2)
		else if ny > gh then
			if not walls_activated then self.y = relative_zero else do_bounce(2)
		end
		if offset_x.abs > 3.0 and offset_y.abs > 3.0 then
			self.x += offset_x
			self.y += offset_y
		end
	end

	# bounce in function of the position of the wall relative to the ball: 1=left or right, 2=top or down
	fun do_bounce(wall_position: Int)
	do
		if wall_position == 1 then
			# if offset_x.abs > 3.0 then game.bounce_sound.play
			offset_x = -offset_x*0.85
		else if wall_position == 2 then
			# if offset_y.abs > 3.0 then game.walld_sound.play
			offset_y = -offset_y*0.85
		end
		if offset_x.abs > 3.0 and offset_y.abs > 3.0 then
		self.x += offset_x
		self.y += offset_y
		end
	end

	fun activate_walls(event: MotionEvent)
	do
		if event.just_went_down then
			walls_activated = not walls_activated
		end
	end
end

class Screen
	var ball_img: Image
	var horizontal_wall_img: Image
	var vertical_wall_img: Image
	var game: Game
	var light = false

	init(app: App, display: Display)
	do
		game = new Game(display, self, app)
		ball_img = app.load_asset("images/ball.png").as(Image)
		horizontal_wall_img = app.load_asset("images/horizontal_wall.png").as(Image)
		vertical_wall_img = app.load_asset("images/vertical_wall.png").as(Image)
		ball_img.scale = game.config.ball_scale
	end

	fun do_frame(display: Display)
	do
		if light then display.clear(1.0, 1.0, 1.0) else display.clear (0.0, 0.0, 0.0)
		display.blit_rotated(ball_img, game.ball.x, game.ball.y, 0.0)
		for wall in game.walls do
			if wall.horizontal then 
					display.blit_rotated(horizontal_wall_img, wall.x, wall.y, 0.0)
			else
					display.blit_rotated(vertical_wall_img, wall.x, wall.y, 0.0)
			end
		end
	end

	fun input(ie: InputEvent): Bool
	do
		if ie isa ASensorProximity then
			if ie.distance == 0.0 then ball_img.scale = game.config.ball_scale_proximity_modifier else ball_img.scale = game.config.ball_scale
		else if ie isa ASensorLight then
				#if ie.light > 3.0 then light = false else light = true
		else
			game.ball.intercepts(ie)
		end
		return true
	end
end

class Game
	var ball: Ball
	var walls: Array[Wall]
	var lines = new Array[Line[Numeric]]
	var width: Float
	var height: Float
	var config = new Configuration
	
	#sounds
	var sound_pool: SoundPool
	var aom_sounds: SoundPool
	#var music: MediaPlayer
	var walld_sound: Sound
	var bounce_sound: Sound

	var img_ori_dim: Int = 256
	fun img_dim: Int do return 210

	init(display: Display, screen: Screen, app: App)
	do
		width = display.width.to_f
		height = display.height.to_f
		ball = new Ball(self, width/2.0, height/2.0, false, screen)
		# Walls initialisation
		var walla = new Wall(width/2.0, height*0.25, true, self)
		var wallb = new Wall(width/2.0, height*0.75, true, self)
		var wallc = new Wall(width*0.25, height/2.0, false, self)
		var walld = new Wall(width*0.75, height/2.0, false, self)
		self.walls = new Array[Wall].with_items(walla, wallb, wallc, walld)
		for wall in walls do
			lines.add(wall.lab)
			lines.add(wall.lcd)
			lines.add(wall.lbc)
			lines.add(wall.lda)
		end

		# walls destroying and bouncing sounds
		sound_pool = new SoundPool


		# walld_sound = sound_pool.load_id(app.native_activity, app.resource_manager.raw_id("walld"))
		walld_sound = app.load_sound_from_res("walld.wav")

		# bounce_sound = sound_pool.load_id(app.native_activity, app.resource_manager.raw_id("bounce"))
		bounce_sound = app.load_sound_from_res("bounce.ogg")

		# TODO: find a good music
		# music = new MediaPlayer.id(app.native_activity, app.resource_manager.raw_id("music"))
		# music.looping = true
		# music.start
	end

	fun do_turn
	do
	ball.do_turn
	end
end

class Configuration
	var ball_scale = 2.0
	var ball_scale_proximity_modifier = 6.0
	var ball_radius = 32.0
	var horizontal_wall_width = 128.0
	var horizontal_wall_height = 32.0
	var vertical_wall_width = 32.0
	var vertical_wall_height = 128.0
end

class Wall
		super Box[Float]
	# coordinates of the center of the wall
	var x: Float
	var y: Float

	# The 4 Points of the wall
	#
	# a ------- b
	#   |     |
	#   |     |
	#   |  x  |
	#   |     |
	#   |     |
	# d ------- c
	var a: Point[Float]
	var b: Point[Float]
	var c: Point[Float]
	var d: Point[Float]
	var lab: Line[Float]
	var lbc: Line[Float]
	var lcd: Line[Float]
	var lda: Line[Float]

	var horizontal: Bool

	init(x,y: Float, horizontal: Bool, game: Game) 
	do
		self.x = x
		self.y = y
		self.horizontal = horizontal
		var cfg = game.config
		if self.horizontal then
				a = new Point[Float]((self.x-cfg.horizontal_wall_width/2.0), (self.y-cfg.horizontal_wall_height/2.0))
				b = new Point[Float]((self.x+cfg.horizontal_wall_width/2.0), (self.y-cfg.horizontal_wall_height/2.0))
				c = new Point[Float]((self.x-cfg.horizontal_wall_width/2.0), (self.y+cfg.horizontal_wall_height/2.0))
				d = new Point[Float]((self.x+cfg.horizontal_wall_width/2.0), (self.y+cfg.horizontal_wall_height/2.0))
		else
				a = new Point[Float]((self.x-cfg.vertical_wall_width/2.0), (self.y-cfg.vertical_wall_height/2.0))
				b = new Point[Float]((self.x+cfg.vertical_wall_width/2.0), (self.y-cfg.vertical_wall_height/2.0))
				c = new Point[Float]((self.x-cfg.vertical_wall_width/2.0), (self.y+cfg.vertical_wall_height/2.0))
				d = new Point[Float]((self.x+cfg.vertical_wall_width/2.0), (self.y+cfg.vertical_wall_height/2.0))
		end
		lab = new Line[Float](a, b)
		lbc = new Line[Float](b, c)
		lcd = new Line[Float](c, d)
		lda = new Line[Float](d, a)
	lrbt(a.x, b.x, a.y, d.y)
	end
end
