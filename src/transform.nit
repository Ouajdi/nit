# This file is part of NIT ( http://www.nitlanguage.org ).
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

# Thansformations that simplify the AST of expressions
# This module transform complex AST `AExpr` nodes into simplier ones
module transform

import astbuilder
import astvalidation
import semantize
intrude import semantize::scope

redef class ToolContext
	var transform_phase: Phase = new TransformPhase(self, [typing_phase, auto_super_init_phase])

	# --no-shortcut-range
	var opt_no_shortcut_range: OptionBool = new OptionBool("Always insantiate a range and its iterator on 'for' loops", "--no-shortcut-range")

	redef init
	do
		super
		self.option_context.add_option(self.opt_no_shortcut_range)
	end
end

private class TransformPhase
	super Phase

	redef fun process_npropdef(npropdef: APropdef)
	do
		var val

		var v = new TransformVisitor(self, npropdef.mpropdef.as(not null))
		v.enter_visit(npropdef)

		val = new ASTValidationVisitor
		val.enter_visit(npropdef)
	end
end

private class TransformVisitor
	super Visitor

	var phase: TransformPhase
	var mmodule: MModule is noinit
	var mclassdef: MClassDef is noinit
	var mpropdef: MPropDef
	var builder: ASTBuilder is noinit

	init
	do
		self.mclassdef = mpropdef.mclassdef
		self.mmodule = mclassdef.mmodule
		self.builder = new ASTBuilder(mmodule, mpropdef.mclassdef.bound_mtype)
	end

	redef fun visit(node)
	do
		if node isa AAnnotations then return
		node.visit_all(self)
		node.accept_transform_visitor(self)
	end

	# Get a primitive class or display a fatal error on `location`.
	fun get_class(location: AExpr, name: String): MClass
	do
		return mmodule.get_primitive_class(name)
	end

	# Get a primitive method or display a fatal error on `location`.
	fun get_method(location: AExpr, name: String, recv: MClass): MMethod
	do
		return phase.toolcontext.modelbuilder.force_get_primitive_method(location, name, recv, mmodule)
	end
end

redef class ANode
	private fun accept_transform_visitor(v: TransformVisitor)
	do
	end
end

redef class AVardeclExpr
	# `var x = y` is replaced with `x = y`
	#
	# Declarations are only useful for scope rules
	# Once names are associated with real objects, ther declaration become useless
	# Therefore, if there is no initial value, then just ignore it
	# Else, replace it with a simple assignment
	redef fun accept_transform_visitor(v)
	do
		var nexpr = n_expr
		if nexpr == null then
			# do nothing
			# note: not detached because the collection is currently under iteration
		else
			var nvar = v.builder.make_var_assign(self.variable.as(not null), nexpr)
			replace_with(nvar)
		end
	end
end

redef class AIfexprExpr
	# is replaced with `AIfExpr`
	# Expression if and statement-if use two distinct classes for historical reasons
	# However, on can replace the `AIfexprExpr` with the simpler `AIfExpr`
	redef fun accept_transform_visitor(v)
	do
		var nif = v.builder.make_if(n_expr, self.mtype)
		nif.n_then.add(n_then)
		nif.n_else.add(n_else)

		replace_with(nif)
	end
end

redef class AOrExpr
	# `x or y` is replaced with `if x then x else y`
	redef fun accept_transform_visitor(v)
	do
		var nif = v.builder.make_if(n_expr, self.mtype)
		nif.n_then.add(n_expr.make_var_read)
		nif.n_else.add(n_expr2)

		replace_with(nif)
	end
end

redef class AImpliesExpr
	redef fun accept_transform_visitor(v)
	do
		# TODO
	end
end

redef class AAndExpr
	# `x and y` is replaced with `if x then y else x`
	redef fun accept_transform_visitor(v)
	do
		var nif = v.builder.make_if(n_expr, self.mtype)
		nif.n_then.add(n_expr2)
		nif.n_else.add(n_expr.make_var_read)

		replace_with(nif)
	end
end

redef class AWhileExpr
	redef fun accept_transform_visitor(v)
	do
		var nloop = v.builder.make_loop
		var nif = v.builder.make_if(n_expr, null)
		nloop.add nif

		var nblock = n_block
		if nblock != null then nif.n_then.add nblock

		var escapemark = self.break_mark.as(not null)
		var nbreak = v.builder.make_break(escapemark)
		nif.n_else.add nbreak

		nloop.break_mark = self.break_mark
		nloop.continue_mark = self.continue_mark

		replace_with(nloop)
	end
end

redef class AForExpr
	redef fun accept_transform_visitor(v)
	do
		var escapemark = self.break_mark
		assert escapemark != null

		var nblock = v.builder.make_block

		var nexpr = n_expr

		# Shortcut on explicit range
		# Avoid the instantiation of the range and the iterator
		if self.variables.length == 1 and nexpr isa ARangeExpr and not v.phase.toolcontext.opt_no_shortcut_range.value then
			var variable = variables.first
			nblock.add v.builder.make_var_assign(variable, nexpr.n_expr)
			var to = nexpr.n_expr2
			nblock.add to

			var nloop = v.builder.make_loop
			nloop.break_mark = escapemark
			nblock.add nloop

			var is_ok = v.builder.make_call(v.builder.make_var_read(variable, variable.declared_type.as(not null)), method_lt.as(not null), [to.make_var_read])

			var nif = v.builder.make_if(is_ok, null)
			nloop.add nif

			var nthen = nif.n_then
			var ndo = v.builder.make_do
			ndo.break_mark = escapemark.continue_mark
			nthen.add ndo

			ndo.add self.n_block.as(not null)

			var one = v.builder.make_int(1)
			var succ = v.builder.make_call(v.builder.make_var_read(variable, variable.declared_type.as(not null)), method_successor.as(not null), [one])
			nthen.add v.builder.make_var_assign(variable, succ)

			var nbreak = v.builder.make_break(escapemark)
			nif.n_else.add nbreak

			replace_with(nblock)
			return
		end

		nblock.add nexpr

		var iter = v.builder.make_call(nexpr.make_var_read, method_iterator.as(not null), null)
		nblock.add iter

		var nloop = v.builder.make_loop
		nloop.break_mark = escapemark
		nblock.add nloop

		var is_ok = v.builder.make_call(iter.make_var_read, method_is_ok.as(not null), null)

		var nif = v.builder.make_if(is_ok, null)
		nloop.add nif

		var nthen = nif.n_then
		var ndo = v.builder.make_do
		ndo.break_mark = escapemark.continue_mark
		nthen.add ndo

		if self.variables.length == 1 then
			var item = v.builder.make_call(iter.make_var_read, method_item.as(not null), null)
			ndo.add v.builder.make_var_assign(variables.first, item)
		else if self.variables.length == 2 then
			var key = v.builder.make_call(iter.make_var_read, method_key.as(not null), null)
			ndo.add v.builder.make_var_assign(variables[0], key)
			var item = v.builder.make_call(iter.make_var_read, method_item.as(not null), null)
			ndo.add v.builder.make_var_assign(variables[1], item)
		else
			abort
		end

		ndo.add self.n_block.as(not null)

		nthen.add v.builder.make_call(iter.make_var_read, method_next.as(not null), null)

		var nbreak = v.builder.make_break(escapemark)
		nif.n_else.add nbreak

		var method_finish = self.method_finish
		if method_finish != null then
			nblock.add v.builder.make_call(iter.make_var_read, method_finish, null)
		end

		replace_with(nblock)
	end
end

redef class AArrayExpr
	# `[x,y]` is replaced with
	#
	# ~~~nitish
	# var t = new Array[X].with_capacity(2)
	# t.add(x)
	# t.add(y)
	# t
	# ~~~
	redef fun accept_transform_visitor(v)
	do
		var nblock = v.builder.make_block

		var nnew = v.builder.make_new(with_capacity_callsite.as(not null), [v.builder.make_int(n_exprs.n_exprs.length)])
		nblock.add nnew

		for nexpr in self.n_exprs.n_exprs do
			var nadd = v.builder.make_call(nnew.make_var_read, push_callsite.as(not null), [nexpr])
			nblock.add nadd
		end
		var nres = nnew.make_var_read
		nblock.add nres

		replace_with(nblock)
	end
end

redef class ACrangeExpr
	# `[x..y]` is replaced with `new Range[X](x,y)`
	redef fun accept_transform_visitor(v)
	do
		if parent isa AForExpr then return # to permit shortcut ranges
		replace_with(v.builder.make_new(init_callsite.as(not null), [n_expr, n_expr2]))
	end
end

redef class AOrangeExpr
	# `[x..y[` is replaced with `new Range[X].without_last(x,y)`
	redef fun accept_transform_visitor(v)
	do
		if parent isa AForExpr then return # to permit shortcut ranges
		replace_with(v.builder.make_new(init_callsite.as(not null), [n_expr, n_expr2]))
	end
end

redef class AParExpr
	# `(x)` is replaced with `x`
	redef fun accept_transform_visitor(v)
	do
		replace_with(n_expr)
	end
end

redef class ASendReassignFormExpr
	# `x.foo(y)+=z` is replaced with
	#
	# ~~~nitish
	# x.foo(y) = x.foo(y) + z
	# ~~~
	#
	# witch is, in reality:
	#
	# ~~~nitish
	# x."foo="(y, x.foo(y)."+"(z))
	# ~~~
	redef fun accept_transform_visitor(v)
	do
		var nblock = v.builder.make_block
		nblock.add(n_expr)

		var read_args = new Array[AExpr]
		var write_args = new Array[AExpr]
		for a in raw_arguments do
			nblock.add(a)
			read_args.add(a.make_var_read)
			write_args.add(a.make_var_read)
		end

		var nread = v.builder.make_call(n_expr.make_var_read, callsite.as(not null), read_args)

		var nnewvalue = v.builder.make_call(nread, reassign_callsite.as(not null), [n_value])

		write_args.add(nnewvalue)
		var nwrite = v.builder.make_call(n_expr.make_var_read, write_callsite.as(not null), write_args)
		nblock.add(nwrite)

		replace_with(nblock)
	end
end

redef class AVarReassignExpr
	# `v += z` is replaced with `v = v + z`
	redef fun accept_transform_visitor(v)
	do
		var variable = self.variable.as(not null)

		var nread = v.builder.make_var_read(variable, read_type.as(not null))

		var nnewvalue = v.builder.make_call(nread, reassign_callsite.as(not null), [n_value])
		var nwrite = v.builder.make_var_assign(variable, nnewvalue)

		replace_with(nwrite)
	end
end

redef class AAttrReassignExpr
	# `x.a += z` is replaced with `x.a = x.a + z`
	redef fun accept_transform_visitor(v)
	do
		var nblock = v.builder.make_block
		nblock.add(n_expr)
		var attribute = self.mproperty.as(not null)

		var nread = v.builder.make_attr_read(n_expr.make_var_read, attribute)
		var nnewvalue = v.builder.make_call(nread, reassign_callsite.as(not null), [n_value])
		var nwrite = v.builder.make_attr_assign(n_expr.make_var_read, attribute, nnewvalue)
		nblock.add(nwrite)

		replace_with(nblock)
	end
end
