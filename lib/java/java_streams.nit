
class JavaIStream
	super BufferedIStream

	var java_stream: NativeInputStream

	redef var end_reached = false

	redef fun fill_buffer
	do
		var size = buffer.length
		var read = java_stream.read_to_buffer(buffer.items, size)
		if read < size then
			end_reached = true
		end
		buffer.length = read
		buffer.pos = 0
	end
end

class JavaByteArray in "Java" `{ byte[] `}
	private fun copy_to_buffer(jni_env: JniEnv, buf: NativeString, size: Int) `{
		char* cbuf = (jni_env*)->GetByteArrayElements(jni_env, recv, JNI_FALSE);
		memcpy(buf, recv, size);
		(jni_env*)->ReleaseByteArrayElements(jni_env, recv, cbuf, JNI_ABORT);
	`}
end

redef class NativeInputStream
	private fun read_to_buffer(buf: FlatBuffer)
	do
		var data = read(size)
		data.copy_to_buffer(data.length, buf.items, buf.size)
	end

	fun read(size: Int): JavaByteArray `{ recv.read(size); `}
end
