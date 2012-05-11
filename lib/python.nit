
in "C header" `{
	#include <python2.6/Python.h>
`}

in "C body" `{
	/*int nitpy_inited = 0;*/
`}

extern PythonObject `{ PyObject * `}
end

extern PythonTuple
	super PythonObject

	#fun length : Int in "Python" `{
		#return len(self)
	#`}
end

