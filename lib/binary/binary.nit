# This file is part of NIT (http://www.nitlanguage.org).
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

# Provides binary reader and writer
#
# ~~~
# var w = new BinaryWriter.open("data.bin")
# w.write_binary 12345
# w.write_binary 'a'
# w.write_binary 12.3456
# w.close
#
# var r = new BinaryReader.open("data.bin")
# print r.read_int
# print r.read_char
# print r.read_float
# r.close
# ~~~
module binary

intrude import standard::file
intrude import binary_base
import binary_generated

redef class BinaryWriter
	# Write up to 8 `Bool` in a byte
	#
	# To be used in combination with `BinaryReader::read_bits`.
	#
	# Ensure: `bits.length <= 8`
	fun write_bits(bits: Bool...)
	do
		assert bits.length <= 8

		var int = 0
		for b in bits.length.times do
			if bits[b] then int += 2**b
		end

		write_char int.ascii
	end
end

redef class BinaryReader
	# Get an `Array` of 8 `Bool` from a byte of the stream
	#
	# To be used in combination with `BinaryWriter::write_bits`.
	fun read_bits: Array[Bool]
	do
		var int = read_char.to_i
		return [for b in 8.times do int.bin_and(2**b) > 0]
	end
end
