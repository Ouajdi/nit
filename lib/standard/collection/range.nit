# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2004-2008 Jean Privat <jean@pryen.org>
#
# This file is free software, which comes along with NIT.  This software is
# distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A
# PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
# is kept unaltered, and a notification of the changes is added.
# You  are  allowed  to  redistribute it and sell it, alone or is a part of
# another product.

# Module for range of discrete objects.
module range

import abstract_collection

# Range of discrete objects.
class Range[E: Discrete]
	super Collection[E]

	redef var first: E

	# Get the last element.
	var last: E

	# Get the element after the last one.
	var after: E

	#     assert [1..10].has(5)
	#     assert [1..10].has(10)
	#     assert not [1..10[.has(10)
	redef fun has(item) do return item >= first and item <= last

	#     assert [1..1].has_only(1)
	#     assert not [1..10].has_only(1)
	redef fun has_only(item) do return first == item and item == last or is_empty

	#     assert [1..10].count(1)	== 1
	#     assert [1..10].count(0)	== 0
	redef fun count(item)
	do
		if has(item) then
			return 1
		else
			return 0
		end
	end

	redef fun iterator do return new IteratorRange[E](self)

	#     assert [1..10].length		== 10
	#     assert [1..10[.length		== 9
	#     assert [1..1].length		== 1
	#     assert [1..-10].length	== 0
	redef fun length
	do
		if is_empty then return 0
		var nb = first.distance(after)
		if nb > 0 then
			return nb
		else
			return 0
		end
	end

	#     assert not [1..10[.is_empty
	#     assert not [1..1].is_empty
	#     assert [1..-10].is_empty
	redef fun is_empty do return first >= after

	# Create a range [`from`, `to`].
	# The syntax `[from..to]` is equivalent.
	#
	#     var a = [10..15]
	#     var b = new Range[Int] (10,15)
	#     assert a == b
	#     assert a.to_a == [10, 11, 12, 13, 14, 15]
	init(from: E, to: E) is old_style_init do
		first = from
		last = to
		after = to.successor(1)
	end

	# Create a range [`from`, `to`[.
	# The syntax `[from..to[` is equivalent.
	#
	#     var a = [10..15[
	#     var b = new Range[Int].without_last(10,15)
	#     assert a == b
	#     assert a.to_a == [10, 11, 12, 13, 14]
	init without_last(from: E, to: E)
	do
		first = from
		last = to.predecessor(1)
		after = to
	end

	# Get a new `Range[E]` with an `offset` from `recv`
	#
	# ~~~
	# assert [0..1[+1 == [1..2[
	# assert [-10..10]+10 == [0..20]
	# ~~~
	fun +(offset: Int): Range[E]
	do
		return new Range[E](first.successor(offset), last.successor(offset))
	end

	# Get a new `Range[E]` with a negative `offset` from `recv`
	#
	# ~~~
	# assert [0..1[-1 == [-1..0[
	# assert [-10..10]-10 == [-20..0]
	# ~~~
	fun -(offset: Int): Range[E] do return self + -offset

	# Two ranges are equals if they have the same first and last elements.
	#
	#     var a = new Range[Int](10, 15)
	#     var b = new Range[Int].without_last(10, 15)
	#     assert a == [10..15]
	#     assert a == [10..16[
	#     assert not a == [10..15[
	#     assert b == [10..15[
	#     assert b == [10..14]
	#     assert not b == [10..15]
	redef fun ==(o) do
		return o isa Range[E] and self.first == o.first and self.last == o.last
	end

	#     var a = new Range[Int](10, 15)
	#     assert a.hash == 455
	#     var b = new Range[Int].without_last(10, 15)
	#     assert b.hash == 432
	redef fun hash do
		# 11 and 23 are magic numbers empirically determined to be not so bad.
		return first.hash * 11 + last.hash * 23
	end
end

private class IteratorRange[E: Discrete]
	# Iterator on ranges.
	super Iterator[E]
	var range: Range[E]
	redef var item is noinit

	redef fun is_ok do return _item < _range.after

	redef fun next do _item = _item.successor(1)

	init
	do
		_item = _range.first
	end
end

redef class Int
	# Returns the range from 0 to `self-1`, is used to do:
	#
	#     var s = new Array[String]
	#     for i in 3.times do s.add "cool"
	#     assert s.join(" ") == "cool cool cool"
	#
	#     s.clear
	#     for i in 10.times do s.add(i.to_s)
	#     assert s.to_s == "0123456789"
	fun times: Range[Int] do return [0 .. self[
end
