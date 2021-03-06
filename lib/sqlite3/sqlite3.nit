# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 201 Alexis Laferrière <alexis.laf@xymus.net>
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

# Services to manipulate a Sqlite3 database
#
# For more information, refer to the documentation of http://www.sqlite.org/docs.html
module sqlite3

private import native_sqlite3
import standard

# A connection to a Sqlite3 database
class Sqlite3DB
	private var native_connection: NativeSqlite3

	# Is this connection to the DB open?
	var is_open = false

	# All `Statement` opened from this connection that must be closed with this connection
	private var open_statements = new Array[Statement]

	# Open a connection to the database file at `path`
	init open(path: Text)
	do
		native_connection = new NativeSqlite3.open(path.to_s)
		if native_connection.is_valid then is_open = true
	end

	# Close this connection to the DB and all open statements
	fun close
	do
		is_open = false

		# close open statements
		for stmt in open_statements do if stmt.is_open then
			stmt.close
		end

		native_connection.close
	end

	# Prepare and return a `Statement`, return `null` on error
	fun prepare(sql: Text): nullable Statement
	do
		var native_stmt = native_connection.prepare(sql.to_s)
		if native_stmt == null then return null

		var stmt = new Statement(native_stmt)
		open_statements.add stmt
		return stmt
	end

	# Execute the `sql` statement and return `true` on success
	fun execute(sql: Text): Bool
	do
		var err = native_connection.exec(sql.to_s)
		return err.is_ok
	end

	# Create a table on the DB with a statement beginning with "CREATE TABLE ", followed by `rest`
	#
	# This method does not escape special characters.
	fun create_table(rest: Text): Bool do return execute("CREATE TABLE " + rest)

	# Insert in the DB with a statement beginning with "INSERT ", followed by `rest`
	#
	# This method does not escape special characters.
	fun insert(rest: Text): Bool do return execute("INSERT " + rest)

	# Replace in the DB with a statement beginning with "REPLACE", followed by `rest`
	#
	# This method does not escape special characters.
	fun replace(rest: Text): Bool do return execute("REPLACE " + rest)

	# Select from the DB with a statement beginning with "SELECT ", followed by `rest`
	#
	# This method does not escape special characters.
	fun select(rest: Text): nullable Statement do return prepare("SELECT " + rest)

	# TODO add more prefix here as needed

	# The latest error message, or `null` if there is none
	fun error: nullable String
	do
		if not native_connection.is_valid then
			var err = sys.sqlite_open_error
			if err == null then return null
			return err.to_s
		end

		var err = native_connection.error
		if err.is_ok then return null
		return err.to_s
	end

	# Returns the id for the last successful insert on the current connection.
	fun last_insert_rowid: Int do return native_connection.last_insert_rowid
end

# A prepared Sqlite3 statement, created from `Sqlite3DB::prepare` or `Sqlite3DB::select`
class Statement
	private var native_statement: NativeStatement

	# Is this statement usable?
	var is_open = true

	# Close and finalize this statement
	fun close
	do
		is_open = false
		native_statement.finalize
	end

	# Reset this statement and return a `StatementIterator` to iterate over the result
	fun iterator: StatementIterator
	do
		native_statement.reset
		return new StatementIterator(self)
	end
end

# A row from a `Statement`
class StatementRow
	# Statement linked to `self`
	var statement: Statement

	# Number of entries in this row
	#
	# require: `self.statement.is_open`
	fun length: Int
	do
		assert statement_closed: statement.is_open

		return statement.native_statement.column_count
	end

	# Returns the `i`th entry on this row
	fun [](i: Int): StatementEntry do return new StatementEntry(statement, i)
end

# An entry on a `StatementRow`
class StatementEntry
	# Statement linked to `self`
	var statement: Statement

	private var index: Int

	# Name of the column
	#
	# require: `self.statement.is_open`
	fun name: String is cached do
		assert statement_closed: statement.is_open

		return statement.native_statement.column_name(index)
	end

	# Get the value of this entry according to its Sqlite type
	#
	# require: `self.statement.is_open`
	fun value: nullable Sqlite3Data
	do
		assert statement_closed: statement.is_open

		var data_type = statement.native_statement.column_type(index)
		if data_type.is_integer then return to_i
		if data_type.is_float then return to_f
		if data_type.is_blob then return to_blob
		if data_type.is_null then return null
		if data_type.is_text then return to_s
		abort
	end

	# Get this entry as `Int`
	#
	# If the Sqlite type of this entry is not an integer, it will be `CAST` to
	# integer. If `null`, returns 0.
	#
	# require: `self.statement.is_open`
	fun to_i: Int
	do
		assert statement_closed: statement.is_open

		return statement.native_statement.column_int(index)
	end

	# Get this entry as `Float`
	#
	# If the Sqlite type of this entry is not a floating point, it will be `CAST`
	# to float. If `null`, returns 0.0.
	#
	# require: `self.statement.is_open`
	fun to_f: Float
	do
		assert statement_closed: statement.is_open

		return statement.native_statement.column_double(index)
	end

	# Get this entry as `String`
	#
	# If the Sqlite type of this entry is not text, it will be `CAST` to text.
	# If null, returns an empty string.
	#
	# require: `self.statement.is_open`
	redef fun to_s
	do
		assert statement_closed: statement.is_open

		var native_string = statement.native_statement.column_text(index)
		if native_string.address_is_null then return ""
		return native_string.to_s_with_copy
	end

	# Get this entry as `Blob`
	#
	# If the Sqlite type of this entry is not a blob, it will be `CAST` to text.
	# If null, returns a NULL pointer.
	#
	# require: `self.statement.is_open`
	fun to_blob: Blob
	do
		assert statement_closed: statement.is_open

		# By spec, we must get the pointer before the byte count
		var pointer = statement.native_statement.column_blob(index)
		var length = statement.native_statement.column_bytes(index)

		return new Blob(pointer, length)
	end
end

# Iterator over the rows of a statement result
class StatementIterator
	super Iterator[StatementRow]

	# Statement linked to `self`
	var statement: Statement

	init
	do
		self.item = new StatementRow(statement)
		self.is_ok = statement.native_statement.step.is_row
	end

	redef var item: StatementRow is noinit

	redef var is_ok: Bool is noinit

	# require: `self.statement.is_open`
	redef fun next
	do
		assert statement_closed: statement.is_open

		var err = statement.native_statement.step
		if err.is_row then
			is_ok = true
		else if err.is_done then
			# Clean complete
			is_ok = false
		else
			# error
			# FIXME do something with the error?
			is_ok = false
		end
	end
end

# A data type supported by Sqlite3
interface Sqlite3Data end

redef universal Int super Sqlite3Data end
redef universal Float super Sqlite3Data end
redef class String
	super Sqlite3Data

	# Return `self` between `'`s and escaping any extra `'`
	#
	#     assert "'; DROP TABLE students".to_sql_string == "'''; DROP TABLE students'"
	fun to_sql_string: String
	do
		return "'{self.replace('\'', "''")}'"
	end
end

# A Sqlite3 blob
class Blob
	super Sqlite3Data

	# Pointer to the beginning of the blob
	var pointer: Pointer

	# Size of the blob
	var length: Int
end
