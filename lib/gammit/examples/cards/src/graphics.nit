# This file is part of NIT (http://www.nitlanguage.org).
#
# Copyright 2014 Alexis Laferrière <alexis.laf@xymus.net>
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

import gammit

import logic

redef class CardRule
	var face: Image
end

redef class DeckRule
	var back: Image
end

redef class Card
	super VisibleSquare

	redef var x = 1.0 - 2.0.rand # pos.x
	redef var y = 1.0 - 2.0.rand # pos.y
	redef var z = 0.0

	fun draw_to(display: Display)
	do
		var context
		var z = 0
		if picked_up then
			# tilt the card a little
			z = 1
		else
		end
	end
end

redef class Table
	var highest_card = 0
	fun draw_to(display: Display)
	do
		for card in cards do card.draw_to display
	end
end

redef class SDLDisplay
	redef fun enable_mouse_motion_events do return true
end

super

var display = new GLESv2GammitDisplay(1024, 768)
display.background_color = new Color.dark_green
#gl_viewport(0, 0, 102, 77)

var texture = display.load_texture_from_file("assets/cards.png")

var card_back = texture.subtexture(24, 0, 11, 15)

var card_colors = new HashMap[String, Texture]
card_colors["heart"] = texture.subtexture( 0,  0, 11, 15)
card_colors["tile"] = texture.subtexture( 0, 16, 11, 15)
card_colors["pike"] = texture.subtexture(12,  0, 11, 15)
card_colors["clover"] = texture.subtexture(12, 16, 11, 15)

var z = 0.0
for card in table.cards do
	card.texture = card_colors.values.rand
	z += 0.00001
	card.z += z
	display.add card
end

var selected_card: nullable Card = null
loop
	# Events
	var events = display.sdl_display.events
	for event in events do
		if event isa SDLQuitEvent then
			break label out
		else if event isa SDLMouseButtonEvent then
			var x = event.x0.to_i
			var y = event.y0.to_i

			if event.pressed0 then
				var new_selection = display.visible_at(x, y)
				print event.button
				if event.is_left_button then
					if new_selection != null and new_selection isa Card then
						print "picked up"
						selected_card = new_selection
					end
				else if event.is_wheel then
					if selected_card != null then new_selection = selected_card

					if new_selection isa Card then
						for card in table.cards do card.z += 0.00001
						new_selection.z = -0.0001
						print "flipped"
					end
				end
			else
				if event.is_left_button and selected_card != null then
					print "dropped"
					selected_card = null
				end
			end
		else if event isa SDLMouseMotionEvent then
			if selected_card != null then
				selected_card.x += event.rel_x/256.0
				selected_card.y += event.rel_y/256.0
			end
		end
	end

	# Drawing
	display.begin_frame
	display.draw_all_the_things
	display.finish_frame

	# Sleep
	33.delay
end label out
