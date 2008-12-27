import kernel

class A
	init ca
	do
		'A'.output
	end

	meth foo
	do
		'a'.output
		'\n'.output
	end
end

class B
special A
#alt1#	init cb
#alt1#	do
#alt1#		'B'.output
#alt1#		'{'.output
#alt1#		ca
#alt1#		'}'.output
#alt1#	end

#alt3#	init cb
#alt3#	do
#alt3#		'B'.output
#alt3#		'{'.output
#alt3#		ca
#alt3#		'}'.output
#alt3#	end

	redef meth foo
	do
		'b'.output
		super
	end
end

class C
special A
#alt2#	init cc
#alt2#	do
#alt2#		'C'.output
#alt2#		'{'.output
#alt2#		ca
#alt2#		'}'.output
#alt2#	end

#alt3#	init cc
#alt3#	do
#alt3#		'C'.output
#alt3#		'{'.output
#alt3#		ca
#alt3#		'}'.output
#alt3#	end

	redef meth foo
	do
		'c'.output
		super
	end
end

class M
special C
	redef meth foo
	do
		'm'.output
		super
	end
end

class N
special B
special M
	redef meth foo
	do
		'n'.output
		super
	end
end

(new A.ca).foo
#alt0#(new B.ca).foo
#alt1#(new B.cb).foo
#alt2#(new B.ca).foo
#alt0#(new C.ca).foo
#alt1#(new C.ca).foo
#alt2#(new C.cc).foo
#alt0#(new M.ca).foo
#alt1#(new M.ca).foo
#alt2#(new M.cc).foo
#alt0#(new N.ca).foo
#alt1#(new N.cb).foo
#alt2#(new N.cc).foo


