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


import standard
intrude import standard::file

class BinaryWriter
	super FileWriter

	init open(path: String)
	do
		self.path = path.to_s
		_file = new NativeFile.io_open_write(self.path.to_cstring)
	end

	fun write_binary(value: BinaryWritable)
	do
		var native = file
		assert native != null

		value.write_binary_to(native)
	end
end

class BinaryReader
	super FileStream

	init open(path: Text)
	do
		self.path = path.to_s
		_file = new NativeFile.io_open_read(self.path.to_cstring)
	end

	redef fun close
	do
		if _file == null or _file.address_is_null then return
		_file.io_close
		_file = null
	end

	fun read_int: Int
	do
		var native = file
		assert native != null
		assert not native.eof

		return native.read_int
	end

	fun read_char: Char
	do
		var native = file
		assert native != null
		assert not native.eof

		return native.read_char
	end

	fun read_float: Float
	do
		var native = file
		assert native != null
		assert not native.eof

		return native.read_float
	end

	fun read_text: Text
	do
		var native = file
		assert native != null
		assert not native.eof

		var length = native.read_int
		assert not native.eof

		var cstr = new NativeString(length+1)
		native.read_native_string(cstr, length)

		return cstr.to_s_with_length(length)
	end
end

redef extern class NativeFile
	fun eof: Bool `{ return feof(recv); `}

	fun read_int: Int `{
		long value;
		fread(&value, sizeof(long), 1, recv);
		return value;
	`}

	fun read_char: Char `{
		unsigned char value;
		fread(&value, sizeof(unsigned char), 1, recv);
		return value;
	`}

	fun read_float: Float `{
		double value;
		fread(&value, sizeof(double), 1, recv);
		return value;
	`}

	fun read_native_string(str: NativeString, length: Int) `{
		fread(str, sizeof(char), length, recv);
	`}
end

interface BinaryWritable
	private fun write_binary_to(stream: NativeFile) is abstract
end

redef class Int
	super BinaryWritable

	redef fun write_binary_to(stream) `{
		fwrite(&recv, sizeof(long), 1, stream);
	`}
end

redef class Char
	super BinaryWritable

	redef fun write_binary_to(stream) `{
		fwrite(&recv, sizeof(unsigned char), 1, stream);
	`}
end

redef class Float
	super BinaryWritable

	redef fun write_binary_to(stream) `{
		fwrite(&recv, sizeof(double), 1, stream);
	`}
end

redef class Text
	super BinaryWritable

	redef fun write_binary_to(stream) do to_cstring.write_binary_to_with_length(stream, length)
end

redef class NativeString
	super BinaryWritable

	redef fun write_binary_to(stream) do write_binary_to_with_length(stream, cstring_length)

	private fun write_binary_to_with_length(stream: NativeFile, length: Int) `{
		fwrite(recv, sizeof(char), length, stream);
	`}
end

var w = new BinaryWriter.open("data.bin")
w.write_binary 12345
w.write_binary 'a'
w.write_binary 12.3456
w.close

var r = new BinaryReader.open("data.bin")
print r.read_int
print r.read_char
print r.read_float
r.close
