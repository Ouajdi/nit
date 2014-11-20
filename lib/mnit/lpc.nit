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

# Services to draw Liberated Pixel Cup (LPC) sprites
#
# ~~~
# var sprite_sheet = new LpcSpriteSheet
# var sprite = new LpcSrite
# ~~~
#
# LPC assets must be downloaded independently and placed in the assets folder
# of the project. With the default values, the path if `assets/lpc-sprites`.
# 
# Recommended artwork source ATOW: 
#
# # Note on the artwork license
#
# The artwork of Liberated Pixel Cup (LPC) is distributed under CC-BY-SA 3.0.
# Thus, any usage of this artwork must be credited to the original artists,
# and all modification to the artwork must be published under the same license.
# 
# See: https://creativecommons.org/licenses/by-sa/3.0/
# See: https://wiki.creativecommons.org/4.0/Games_3d_printing_and_functional_content#Source_release.3F
#
# # Features:
#
# - [x] All human bodies
# - [x] Some weapons (dagger, bow and javelin)
# - [x] Most apparel available to all genders
# - [ ] Apparel that are gender specific
# - [ ] Other species (skeletton, orc, etc.)
# - [ ] Small features (bracelets, ears, etc.)
# - [ ] Static API where we use `HashMap`: `bodies` and `hair`
# - [ ] Extra weapons (oversized and others)
# - [ ] Update API to use enumerations and manage better the genders
module lpc

import app
import mnit::assets
import colors

# Utility class to manage and order sprite layers to draw using `blit_lpc_sprite`
class LpcSprite
	# The sequence of layers to draw in the specified color
	var draw_sequence: Array[Couple[LpcSpriteLayer, Color]]

	# Add a `layer` to this sprite, may duplicate layers
	#
	# A `null` `color` will be treated as white.
	fun add(layer: LpcSpriteLayer, color: nullable Color)
	do
		if color == null then color = new Color.white

		draw_sequence.add(new Couple[LpcSpriteLayer, Color](layer, color))
	end

	# Does this sprite has `layer`?
	fun has(layer: LpcSpriteLayer): Bool
	do
		for couple in draw_sequence do
			if couple.first == layer then
				return true
			end
		end
		return false
	end

	# What is the color of the `layer` in this sprite?
	# 
	# Returns `null` when this sprite doesn't have `layer`.
	fun [](layer: LpcSpriteLayer): nullable Color
	do
		for couple in draw_sequence do
			if couple.first == layer then
				return couple.second
			end
		end

		return null
	end

	# Set the `color` of the `layer`, add the `layer` if it is not already in this sprite
	#
	# A `null` `color` will be treated as white.
	fun []=(layer: LpcSpriteLayer, color: nullable Color)
	do
		if color == null then color = new Color.white

		for couple in draw_sequence do
			if couple.first == layer then
				couple.second = new Color.white
				return
			end
		end

		add(layer, color)
	end

	# Clear all layers from this sprite
	fun clear do draw_sequence.clear
end

# All of LPC sprite layers
#
# Loaded as soon as the instance is created.
class LpcSpriteSheet
	# Directory within the assets folder where the resources are located
	var dir = "lpc-sprites/"

	# Load from a custom directory, within the assets directory
	init custom_dir(dir: String)
	do
		dir = dir
		init
	end

	# Naked bodies of different skin tone
	var bodies = new HashMap[Gender, HashMap[String, LpcSpriteLayer]]

	# Plate armor for torso
	var torso_plate = new HashMap[Gender, LpcSpriteLayer]
	# Plate armor for arms
	var arms_plate = new HashMap[Gender, LpcSpriteLayer]
	# Plate armor for legs
	var leg_plate = new HashMap[Gender, LpcSpriteLayer]
	# Plate armor for feet
	var feet_plate = new HashMap[Gender, LpcSpriteLayer]
	# Plate armor for hands
	var hands_plate = new HashMap[Gender, LpcSpriteLayer]

	# Chain armor torso
	var torso_chain = new HashMap[Gender, LpcSpriteLayer]

	# Shirt
	var torso_shirts = new HashMap[Gender, LpcSpriteLayer]

	# Hair styles
	var hair = new HashMap[Gender, HashMap[String, LpcSpriteLayer]]

	# Chain helm
	var head_helm_chainhat = new HashMap[Gender, LpcSpriteLayer]
	# Golden helm 
	var head_helm_golden = new HashMap[Gender, LpcSpriteLayer]
	# Metal helm
	var head_helm_metal = new HashMap[Gender, LpcSpriteLayer]

	# Cloth hood
	var head_hood_cloth = new HashMap[Gender, LpcSpriteLayer]
	# Chain mail hood
	var head_hood_chain = new HashMap[Gender, LpcSpriteLayer]

	# Pants
	var leg_pants = new HashMap[Gender, LpcSpriteLayer]
	# Skirt, TODO
	#var leg_skirt = new HashMap[Gender, LpcSpriteLayer]

	# Shoes
	var feet_shoe = new HashMap[Gender, LpcSpriteLayer]

	# Dagger
	var weapon_dagger = new HashMap[Gender, LpcSpriteLayer]
	# Spear
	var weapon_spear = new HashMap[Gender, LpcSpriteLayer]
	# Bow
	var weapon_bow = new HashMap[Gender, LpcSpriteLayer]

	# Cloth belt
	var belt_cloth = new HashMap[Gender, LpcSpriteLayer]

	# Leather gloves
	var hands_leather = new HashMap[Gender, LpcSpriteLayer]

	init
	do
		for gender in [male, female] do
			bodies[gender] = new HashMap[String, LpcSpriteLayer]
			for color in ["dark", "dark2", "light", "tanned", "tanned2"] do
				bodies[gender][color] = new LpcSpriteLayer(app.load_image(dir/"body/{gender}/{color}.png"))
			end

			torso_plate[gender] = new LpcSpriteLayer(app.load_image(dir/"torso/plate/chest_{gender}.png"))
			arms_plate[gender] = new LpcSpriteLayer(app.load_image(dir/"torso/plate/arms_{gender}.png"))
			leg_plate[gender] = new LpcSpriteLayer(app.load_image(dir/"legs/armor/{gender}/metal_pants_{gender}.png"))
			feet_plate[gender] = new LpcSpriteLayer(app.load_image(dir/"feet/armor/{gender}/metal_boots_{gender}.png"))
			hands_plate[gender] = new LpcSpriteLayer(app.load_image(dir/"hands/gloves/{gender}/metal_gloves_{gender}.png"))

			torso_chain[gender] = new LpcSpriteLayer(app.load_image(dir/"torso/chain/mail_{gender}.png"))

			var hair_map = new HashMap[String, LpcSpriteLayer]
			hair[gender] = hair_map
			for style in ["bangs", "bangsshort", "jewfro", "longknot", "messy2",
				"page2", "plain", "princess", "shoulderl", "unkempt", 
				"bangslong", "bedhead", "long", "loose", "mohawk",
				"parted", "ponytail", "shorthawk", "shoulderr", "xlong", 
				"bangslong2", "bunches", "longhawk", "messy1", "page",
				"pixie", "ponytail2", "shortknot", "swoop", "xlongknot"] do

				hair_map[style] = new LpcSpriteLayer(app.load_image(dir/"hair/{gender}/{style}/white.png"))
			end

			head_helm_chainhat[gender] = new LpcSpriteLayer(app.load_image(dir/"head/helms/{gender}/chainhat_{gender}.png"))
			head_helm_golden[gender] = new LpcSpriteLayer(app.load_image(dir/"head/helms/{gender}/golden_helm_{gender}.png"))
			head_helm_metal[gender] = new LpcSpriteLayer(app.load_image(dir/"head/helms/{gender}/metal_helm_{gender}.png"))

			head_hood_cloth[gender] = new LpcSpriteLayer(app.load_image(dir/"head/hoods/{gender}/cloth_hood_{gender}.png"))
			head_hood_chain[gender] = new LpcSpriteLayer(app.load_image(dir/"head/hoods/{gender}/chain_hood_{gender}.png"))

			leg_pants[gender] = new LpcSpriteLayer(app.load_image(dir/"legs/pants/{gender}/white_pants_{gender}.png"))
			#leg_skirt[gender] = new LpcSpriteLayer(app.load_image(dir/"legs/skirt/{gender}/robe_skirt_{gender}.png"))

			feet_shoe[gender] = new LpcSpriteLayer(app.load_image(dir/"feet/shoes/{gender}/maroon_shoes_{gender}.png"))

			weapon_dagger[gender] = new LpcSpriteLayer(app.load_image(dir/"weapons/right hand/{gender}/dagger_{gender}.png"))
			weapon_spear[gender] = new LpcSpriteLayer(app.load_image(dir/"weapons/right hand/{gender}/spear_{gender}.png"))
			weapon_bow[gender] = new LpcSpriteLayer(app.load_image(dir/"weapons/right hand/either/recurvebow.png"))

			belt_cloth[gender] = new LpcSpriteLayer(app.load_image(dir/"belt/cloth/{gender}/white_cloth_{gender}.png"))

			hands_leather[gender] = new LpcSpriteLayer(app.load_image(dir/"hands/bracers/{gender}/leather_bracers_{gender}.png"))
		end

		torso_shirts[male] = new LpcSpriteLayer(app.load_image(dir/"torso/shirts/longsleeve/male/white_longsleeve.png"))
		torso_shirts[female] = new LpcSpriteLayer(app.load_image(dir/"torso/shirts/sleeveless/female/white_sleeveless.png"))
	end
end

# Gender of an LPC sprite
class Gender
	# TODO
	# private init
	# or replace with an enum

	# Is this the male gender?
	var is_male: Bool

	# Is this the female gender?
	fun is_female: Bool do return not is_male

	redef fun to_s do return if is_male then "male" else "female"
end

# The male gender
fun male: Gender do return once new Gender(true)

# The female gender
fun female: Gender do return once new Gender(false)

# A Single layer of the LPC spritesheet
class LpcSpriteLayer
	init(image: Image)
	do
		var h = 64
		var w = 64

		# walking left
		var y = 9*h
		for i in [0..6[ do
			var x = i*w
			walking_left_imgs.add image.subimage(x, y, w, h)
		end

		# walking right
		y = 11*h
		for i in [0..6[ do
			var x = i*w
			walking_right_imgs.add image.subimage(x, y, w, h)
		end

		# slash left
		y = 13*h
		for i in [0..6[ do
			var x = i*w
			slash_left.add image.subimage(x, y, w, h)
		end

		# slash right
		y = 15*h
		for i in [0..6[ do
			var x = i*w
			slash_right.add image.subimage(x, y, w, h)
		end

		# correct size
		for i in walking_left_imgs do i.scale = 0.5#*master_scale
		for i in walking_right_imgs do i.scale = 0.5#*master_scale
	end

	# Images of this layer for walking left
	private var walking_left_imgs = new Array[Image]

	# Images of this layer for walking right
	private var walking_right_imgs = new Array[Image]

	# Images of this layer for slashing left
	private var slash_left = new Array[Image]

	# Images of this layer for slashing right
	private var slash_right = new Array[Image]
end

redef class Display
	# Blit LPC sprite layers with the given colors doing an `lpc_action` at `tick`
	fun blit_lpc_sprite(sprite: LpcSprite, lpc_action: LpcAction, tick: Int, x, y: Numeric, angle: Float)
	do
		assert self isa Opengles1Display
		for seq in draw_sequence do
			var color = seq.first
			color2 color
			for sheet in seq.second do
				# Select image sheet
				var imgs
				if lpc_action.is_walking then
					if lpc_action.is_going_left then
						imgs = sheet.walking_left_imgs
					else imgs = sheet.walking_right_imgs
				else if lpc_action.is_slashing then
					if lpc_action.is_going_left then
						imgs = sheet.slash_left
					else imgs = sheet.slash_right
				else # standing
					if lpc_action.is_going_left then
						imgs = sheet.walking_left_imgs
					else imgs = sheet.walking_right_imgs
					tick = 0
				end

				var i = (tick/4) % imgs.length
				var img = imgs[i]
				blit_rotated(img, x, y, angle)
			end
		end
		color2(new Color.white)
	end
end

# An action in the LPC spritesheet
class LpcAction
	# TODO Replace by an enum

	# Is this character walking?
	var is_walking: Bool

	# Is this character slashing?
	var is_slashing: Bool

	# Is this character heading left?
	var is_going_left: Bool
end
