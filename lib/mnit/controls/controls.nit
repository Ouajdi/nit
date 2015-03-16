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

# Controls for the Mnit display system
#
# Provides both common classes such as `Button` and services to implement.
module controls

import mnit_display
import mnit_input
import geometry
import tileset

# Abstract control at the head of the controls hierarchy
abstract class Control

	# Draw `self` to `display`
	fun draw(display: Display) do end

	# Propagation of an input `event` within `screen`
	#
	# Returns `true` if intercepted.
	#
	# Usually a `Control` will intercept an event when it acts upon it.
	fun input(screen: Screen, event: InputEvent): Bool do return false

	# What class of `ContainerControl` can hold `self`
	type PARENT: ContainerControl

	# `PARENT` controller holding self, if any
	var parent: nullable PARENT = null
end

# Clickable or tappable on-screen control
#
# TODO rename to VisibleControl
class PointerControl
	super Control

	# Does `event` points within `self`?
	fun within(event: PointerEvent): Bool is abstract

	# Reference point on-screen
	var anchor: nullable IPoint[Numeric] = null

	# Padding applied when needing
	#
	# This value is used by many subclasses for different purposes.
	# This won't affect fields that are centered.
	var padding = 8 is writable
end

# Selectable control to capture keyboard inputs
class SelectableControl
	super Control

	# Is `self` currently selected by any screen?
	#
	# Set and unset by `select` and `unselect`.
	#
	# This is only an heuristice since only `Screen` knows what is the locally selected control.
	# It is very useful for drawing and usually display the intended behavior.
	var selected = false

	# Select `self` and `unselect` the previously selected control in `screen`
	fun select(screen: Screen)
	do
		var old = screen.selected
		if old != null then old.selected = false

		selected = true
		screen.selected = self
	end

	# Unselect `self` as the selected control in `screen`
	#
	# Also unselect the previously selected control in `screen`,
	# even if not `self`.
	fun unselect(screen: Screen)
	do
		var old = screen.selected
		if old != null then old.selected = false

		selected = false
		screen.selected = null
	end
end

# Control composed of other controls
#
# TODO compose of list intead of subclass
class ContainerControl
	super Control
	super List[Control]

	# Draw self and subcontrols
	redef fun draw(display)
	do
		for control in self do control.draw(display)
	end

	# A `ContainerControl` relay this call to its children
	#
	# Subclasses may intercept the event by themselves,
	# but should usally call super.
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

# Control to manage a whole game screen
#
# This may very well not cover the whole screen,
# it can be used to manage transition between screens.
class Screen
	super ContainerControl

	# Which `SelectableControl` is selected, if any
	var selected: nullable SelectableControl = null
end

# Receiver called by controls when activated by an input event
#
# Each button is associated with one HitReceiver
#
# TODO rename HitReceiver to EventListener
interface HitReceiver

	# React when receiving `event` on `sender`
	fun hit(sender: Control, event: InputEvent) is abstract
end

# A collection of `HitReceiver`
class MultipleHitReceiver
	super HitReceiver
	super List[HitReceiver]

	redef fun hit(sender, event) do for r in self do r.hit(sender, event)
end

# Simple clickable visible control
class Button
	super PointerControl

	# Listeners on events
	var receiver: HitReceiver

	# Behavior on click raised by an `InputEvent`
	fun on_click(event: InputEvent) do receiver.hit(self, event)

	# Raises `on_click` on a depressed `PointerEvent` `input`
	redef fun input(screen, event)
	do
		if event isa PointerEvent and within(event) then
			if event.depressed then on_click(event)
			return true
		end

		return false
	end
end

# Invisible control catching `keys`
class KeyCatcher
	super Control

	# TODO
	var receiver: HitReceiver

	# Catched keys
	#
	# The key ids are platform dependent.
	# Use the SDL key name and the Android key code as `String`.
	var keys: Array[String]

	redef fun input(screen, event)
	do
		if event isa KeyEvent and keys.has(event.name) then
			receiver.hit(self, event)
			return true
		end

		return false
	end
end

# Rectangular visible control
class RectangleControl
	super PointerControl

	# TODO use anchor
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

# A simple rectangular button
class RectangleButton
	super Button
	super RectangleControl
end

# Vertical list of controls
class RectangleMenu
	super RectangleControl
	super ContainerControl

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

#redef class App
	#var default_control_font: nullable TileSetFont
#end

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
#
# Intercepts all keyboard inputs when `selected`.
class TextInputControl
	super RectangleControl
	super SelectableControl

	# Real text entered in this field
	#
	# This can be different from `visible_text`.
	var text = ""

	# Listeners on the event when hitting enter on the control
	var receiver: HitReceiver

	# Text to show besides the input field
	var label_text: String

	# `TileSetFont` used to draw `visible_text` and `label_text`
	var font: TileSetFont is writable

	# Text to show on screen
	protected fun visible_text: String do return text

	redef fun draw(display)
	do
		draw_back(display)

		display.text(label_text, font, left+8, top+16)

		if not text.is_empty then display.text(visible_text, font, left+16, top+32)
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
								text = text + key
							end
						else if event.name == "enter" then
							receiver.hit(self, event)
						else if event.name == "backspace" then
							if not text.is_empty then
								text = text.substring(0, text.length-1)
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

	# Is `char` an acceptable input?
	fun accepts_char(char: Char): Bool do return char >= ' ' and char <= '~'
end

# Text input for passwords and other hidden text
class PasswordInputControl
	super TextInputControl

	# Shows only '*'
	redef fun visible_text do return "*" * text.length
end

# Text input limited to numbers
class IntInputControl
	super TextInputControl

	redef fun accepts_char(char) do return char >= '0' and char <= '9'

	# Number entered in the field, if any
	fun number: nullable Int
	do
		if text.is_empty then return null
		return text.to_i
	end

	# Set number in the field
	fun number=(value: nullable Int)
	do
		if value == null then
			text = ""
		else text = value.to_s
	end

	redef fun text=(value)
	do
		assert value.is_empty or value.is_numeric
		super
	end
end

# Simple separator control (mainly for RectangleMenu and HorizontalMenu)
class Separator
	super RectangleControl

	redef fun draw(display) do draw_back(display)
end

# Simple rectangle button using an image
class ImageRectangleButton
	super RectangleButton

	# Image to display centered on this button
	var image: Image is writable

	redef fun draw(display)
	do
		var t = top.to_f
		var b = bottom.to_f
		var l = left.to_f
		var r = right.to_f

		display.blit_stretched(image, l, b, l, t, r, t, r, b)

		super
	end
end
