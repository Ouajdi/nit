# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2013-2014 Alexis Laferrière <alexis.laf@xymus.net>
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

# Buisness logic of a calculator
module calculator_logic

class CalculatorContext
	var result: nullable Numeric = null

	var last_op: nullable Char = null

	var current: nullable FlatBuffer = null
	fun display_text: String
	do
		var result = result
		var last_op = last_op
		var current = current

		var buf = new FlatBuffer

		if result != null and (current == null or last_op != '=') then
			if last_op == '=' then buf.append "= "

			buf.append result.to_s
			buf.add ' '
		end

		if last_op != null and last_op != '=' then
			buf.add last_op
			buf.add ' '
		end

		if current != null then
			buf.append current.to_s
			buf.add ' '
		end

		return buf.to_s
	end

	fun push_op( op : Char )
	do
		apply_last_op_if_any
		if op == 'C' then
			self.result = null
			last_op = null
		else
			last_op = op # store for next push_op
		end

		# prepare next current
		self.current = null
	end

	fun push_digit( digit : Int )
	do
		var current = current
		if current == null then current = new FlatBuffer
		current.add digit.to_s.chars.first
		self.current = current

		if last_op == '=' then
			self.result = null
			last_op = null
		end
	end

	fun switch_to_decimals
	do
		var current = current
		if current == null then current = new FlatBuffer.from("0")
		if not current.chars.has('.') then current.add '.'
		self.current = current
	end

	fun apply_last_op_if_any
	do
		var op = last_op

		var result = result
		if result == null or result isa NotANumber then result = 0

		var current = current
		if current == null then current = new FlatBuffer

		if op == null then
			result = current.to_n
		else if op == '+' then
			result = result.add(current.to_n)
		else if op == '-' then
			result = result.sub(current.to_n)
		else if op == '/' then
			result = result.div(current.to_n)
		else if op == '*' then
			result = result.mul(current.to_n)
		end
		self.result = result
		self.current = null
	end
end

redef class Text
	# Get the numeric version of `self`
	#
	# require: `is_numeric`
	fun to_n: Numeric
	do
		if chars.has('.') then return to_f
		return to_i
	end
end

redef interface Numeric
	# Universal `+` with any `Numeric`
	#
	# ~~~~
	# assert 1.add(1) == 2
	# assert 1.add(0.1) == 1.1
	# assert 1.1.add(0.1) == 1.2
	# assert 1.1.add(1) == 2.1
	# ~~~~
	fun add(other: Numeric): Numeric is abstract

	# Universal `-` with any `Numeric`
	fun sub(other: Numeric): Numeric is abstract

	# Universal `/` with any `Numeric`
	fun div(other: Numeric): Numeric is abstract

	# Universal `*` with any `Numeric`
	fun mul(other: Numeric): Numeric is abstract
end

redef universal Int
	redef fun add(other) do if other isa Float then
		return to_f + other
	else return self + other.as(Int)

	redef fun sub(other) do if other isa Float then
		return to_f - other
	else return self - other.as(Int)

	redef fun mul(other) do if other isa Float then
		return to_f * other
	else return self * other.as(Int)

	redef fun div(other) do if other isa Float then
		if other == 0.0 then return new NotANumber
		return to_f / other
	else
		if other == 0 then return new NotANumber
		return self / other.as(Int)
	end
end

redef universal Float
	redef fun add(other) do return self + other.to_f
	redef fun sub(other) do return self - other.to_f

	redef fun div(other) do
		other = other.to_f
		if other == 0.0 then return new NotANumber
		return self / other.to_f
	end

	redef fun mul(other) do return self * other.to_f
	redef fun to_s do return to_precision(6)
end

class NotANumber
	super Numeric

	private init do end

	redef fun add(other) do abort
	redef fun sub(other) do abort
	redef fun div(other) do abort
	redef fun mul(other) do abort
	redef fun to_i do abort
	redef fun to_f do abort
	redef fun to_s do return "NaN"
end
