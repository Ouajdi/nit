# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2011-2014 Alexis Laferrière <alexis.laf@xymus.net>
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

# Provides controls bases for mnit display system
module controls

import mnit_display
import mnit_input
import geometry
import tileset

# General control class
class Control
	# draw control
	fun draw(display: Display) do end

	# try to accept input
	# returns true if intercepted
	fun input(screen: Screen, event: InputEvent): Bool do return false

	var parent: nullable ContainerControl = null
end

# Clickable control
class PointerControl
	super Control

	# event is within control
	fun within(event: PointerEvent): Bool is abstract

	var anchor: nullable IPoint[Numeric] = null
end

# Selectable control to catch keyboard inputs
class SelectableControl
	super Control

	var selected: Bool = false
	
	fun select(screen: Screen)
	do
		if screen.selected != null then screen.selected.selected = false
		
		selected = true
		screen.selected = self
	end
	
	fun unselect(screen: Screen)
	do
		if screen.selected != null
		then
			screen.selected.selected = false
		end
		
		selected = false
		screen.selected = null
	end
end

# Control holding other controls
class ContainerControl
	super Control
	super List[Control]
	
	redef fun draw(display)
	do
		for control in self do control.draw(display)
	end
	
	redef fun input(screen, event)
	do
		var intercepted = false
		for control in self do if control.input(screen, event) then
			intercepted = true
			break
		end
		return intercepted
	end

	redef fun add(e)
	do
		super

		e.parent = self
	end
end

# Control to manage a whole screen
class Screen
	super ContainerControl

	# which (if any) selectable control is selected
	var selected: nullable SelectableControl = null
end

# Receiver called by controls when activated by an input event
# Each button is associated with one HitReceiver
interface HitReceiver
	fun hit(sender: Control, event: InputEvent) is abstract
end

# HitReceiver collection
class MultipleHitReceiver
	super HitReceiver
	super List[HitReceiver]

	redef fun hit(sender, event) do for r in self do r.hit(sender, event)
end

# Control activated by a pointer event
class Button
	super PointerControl

	var receiver: HitReceiver

	fun on_click(event: InputEvent) do receiver.hit(self, event)
	
	redef fun input(screen, event)
	do
		if event isa PointerEvent and within(event) then
			if event.depressed then on_click(event)
			return true
		end
		
		return false
	end
end

# Precise key listener but invisible control
class KeyCatcher
	super Control

	var receiver: HitReceiver
	var keys: Array[String] # TODO change to char
	
	redef fun input(screen, event)
	do
		if event isa KeyEvent and event.to_c != null and keys.has(event.to_c.to_s) then
			receiver.hit(self, event)
			return true
		end
		
		return false
	end
end

class RectangleControl
	super PointerControl

	var top: Int = 0 is writable
	var left: Int = 0 is writable
	var width: Int = 0
	var height: Int = 0
	
	fun right: Int do return left + width
	fun right=(v: Int) do width = v-left
	fun bottom: Int do return top + height
	fun bottom=(v: Int) do height = v-top
	
	fun center_x: Int do return left + width / 2
	fun center_y: Int do return top + height / 2
	
	fun set_anchor(left, top: Int): SELF
	do
		self.left = left
		self.top = top
		return self
	end

	fun set_size(width, height: Int): SELF
	do
		self.width = width
		self.height = height

		var parent = parent
		if parent isa RectangleMenu then parent.child_changed_size self

		return self
	end
	
	redef fun within(event)
	do
		return event.y.to_i > top and event.y.to_i < bottom and
				event.x.to_i > left and event.x.to_i < right
	end

	fun draw_back(display: Display) do end
end

class RectangleButton
	super Button
	super RectangleControl
end

# Vertical list of controls
class RectangleMenu
	super RectangleControl
	super ContainerControl

	var padding: Int = 8
	
	redef fun top=(t: Int)
	do
		var d = t - top
		for c in self do if c isa RectangleControl then c.top += d
		
		super
	end
	
	redef fun left=(l: Int)
	do
		var d = l - left
		for c in self do if c isa RectangleControl then c.left += d 
	
		super
	end

	redef fun add(ctrl)
	do
		assert ctrl isa RectangleControl

		insert_in_menu(ctrl)
		
		super
	end
	
	# adapts current control size to all buttons
	# adpts button top left to this control
	#
	# TODO replace with update_size
	protected fun insert_in_menu(ctrl: RectangleControl)
	do
		ctrl.top = bottom
		ctrl.left = left + padding
		
		height += ctrl.height + padding
		
		if width < ctrl.width + 2*padding then width = ctrl.width + 2*padding
	end

	protected fun update_size
	do
		var height = padding
		var width = 0
		for ctrl in self do if ctrl isa RectangleControl then
			ctrl.top = top + height
			ctrl.left = left + padding

			height += ctrl.height + padding
			width = width.max(ctrl.width)
		end

		self.height = height
		self.width = width + 2 * padding
	end
	
	redef fun clear
	do
		height = padding
		
		super
	end
	
	redef fun draw(display)
	do
		super
		
		draw_back(display)
		
		# TODO
		# below is a hack
		# should be handled by a call to super:(
		for control in self do control.draw(display)
	end
	
	redef fun input(screen, event)
	do
		# var intercepted = super # TODO a call to super should work here

		var intercepted: Bool = false
		for control in self do if control.input(screen, event) then
			intercepted = true
			break
		end
		
		if not intercepted and event isa PointerEvent and within(event) then
			intercepted = true
		end
		
		return intercepted
	end

	private fun child_changed_size(child: Control)
	do
		update_size
	end
end

class HorizontalMenu
	super RectangleMenu

	redef fun insert_in_menu(ctrl: RectangleControl)
	do
		ctrl.top = top + padding
		ctrl.left = right
		
		width += ctrl.width + padding
		
		if height < ctrl.height + 2*padding then
			height = ctrl.height + 2*padding
		end
	end
	
	redef fun clear
	do
		width = padding
		
		super
	end
end

class TextRectangleButton
	super RectangleButton

	var text: String is writable
	var font: TileSetFont
	
	redef fun draw(display)
	do
		draw_back(display)
		display.text(text, font, left+8, top+16)
	end
end

# Control to input text with the keyboard
class TextInputControl
	super RectangleControl
	super SelectableControl
	
	var receiver: HitReceiver

	var label_text: String
	
	var input_img: nullable Image = null
	var input_text: String = ""
	
	var font: TileSetFont
	
	var padding: Int = 8
	
	fun text: String do return input_text
	fun text= (t: String)
	do
		input_text = t
		input_img = null
	end
	
	private fun visible_text: String do return input_text
	
	redef fun draw(display)
	do
		draw_back(display)

		display.text(label_text, font, left+8, top+16)

		if not input_text.is_empty then display.text(visible_text, font, left+16, top+32)
	end
	
	redef fun input(screen, event)
	do
		if event isa KeyEvent then
			if selected then
				if not event.is_down then
					var c = event.to_c
					if c != null then
						var key = c.to_s
						if key.length == 1 then
							var char = key[0]
							if accepts_char(char) then
								text = input_text + key
							end
						else if key == "enter" then
							receiver.hit(self, event)
						else if key == "backspace" then
							if not text.is_empty then
								text = input_text.substring(0, input_text.length-1)
							end
						end
					end
				end

				return true
			end
		else if event isa PointerEvent then
			if within(event) then
				select(screen)
				return true
			end
		end
		
		return false
	end
	
	# is this a recognized character?
	fun accepts_char(char: Char): Bool
	do
		return char >= ' ' and char <= '~'
	end
end

# Hidden text input
class PasswordInputControl
	super TextInputControl
	
	redef fun visible_text do return "*" * input_text.length
end

# Text input limited to numbers
class NumberInputControl
	super TextInputControl
	
	redef fun accepts_char(char) do return char >= '0' and char <= '9'
	
	fun number: nullable Int
	do
		if input_text.is_empty then
			return null
		else return input_text.to_i
	end
end

# Simple separator control (mainly for RectangleMenu and HorizontalMenu)
class Separator
	super RectangleControl
	
	redef fun draw(display) do draw_back(display)
end

# Basic rectangle button using an image
class ImageRectangleButton
	super RectangleButton

	var img: Image
	
	redef fun draw(display)
	do
		var t = top.to_f
		var b = bottom.to_f
		var l = left.to_f
		var r = right.to_f

		display.blit_stretched(img, l, b, l, t, r, t, r, b)
		
		super
	end
end
