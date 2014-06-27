import java

extern class JavaArray[JO: JavaObject] `{ Object[] `}
	super Sequence[JO]

	new of_byte(size: Int) in "Java" `{ return new byte[size]; `}
	new of_short(size: Int) in "Java" `{ return new short[size]; `}
	new of_long(size: Int) in "Java" `{ return new long[size]; `}
	new of_float(size: Int) in "Java" `{ return new float[size]; `}
	new of_double(size: Int) in "Java" `{ return new double[size]; `}
	new of_boolean(size: Int) in "Java" `{ return new boolean[size]; `}
	new of_char(size: Int) in "Java" `{ return new char[size]; `}
	new of_string(size: Int) in "Java" `{ return new String[size]; `}

	redef fun [](i) in "Java" `{ return recv[i]; `}

	redef fun length in "Java" `{ return recv.length; `}

	redef fun add(e) in "Java" `{ recv.add(e); `}

	redef fun insert(e, i) in "Java" `{ recv[i] = e; `}

	redef fun pop in "Java" `{ return recv.pop(); `}

	redef fun to_a
	do
		var arr = new Array[JO]
		for i in self do arr.add i
		return arr
	end
end
