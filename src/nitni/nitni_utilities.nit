# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2013 Alexis Laferrière <alexis.laf@xymus.net>
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

# Support utilities to use nitni
import nitni_base

redef class MMethod
	fun build_cname(recv_mtype: MClassType, from_mmodule: MModule, suffix: nullable String, length: SignatureLength, call_context: CallContext): String
	do
		var cname
		if self.is_init then
			if self.name == "init" or self.name == "new" then
				cname = "new_{recv_mtype.mangled_cname}"
			else
				cname = "new_{recv_mtype.mangled_cname}_{self.short_cname}"
			end
		else
			cname = "{recv_mtype.mangled_cname}_{self.short_cname}"
		end

		if suffix != null then cname = "{cname}{suffix}"

		if length.long then cname = "{from_mmodule.name}___{cname}"

		return cname
	end

	# `suffix` to the method name
	# `call_context` service used to name types and casts (by default it is the C type namer)
	fun build_csignature(recv_mtype: MClassType, from_mmodule: MModule, suffix: nullable String, length: SignatureLength, call_context: CallContext): String
	do
		var signature = self.intro.msignature
		assert signature != null

		var creturn_type
		if self.is_init then
			creturn_type = call_context.name_mtype(recv_mtype)
		else if signature.return_mtype != null then
			var ret_mtype = signature.return_mtype
			ret_mtype = ret_mtype.resolve_for(recv_mtype, recv_mtype, from_mmodule, true)
			creturn_type = call_context.name_mtype(ret_mtype)
		else
			creturn_type = "void"
		end

		var cname = build_cname(recv_mtype, from_mmodule, suffix, length, call_context)

		var cparams = new List[String]
		if not self.is_init then
			cparams.add( "{call_context.name_mtype(recv_mtype)} recv" )
		end
		for p in signature.mparameters do
			var param_mtype = p.mtype.resolve_for(recv_mtype, recv_mtype, from_mmodule, true)
			cparams.add( "{call_context.name_mtype(param_mtype)} {p.name}" )
		end

		return "{creturn_type} {cname}( {cparams.join(", ")} )"
	end

	# `suffix` to the method name
	# TODO `name_pattern` of the method, use %n to use default name
	# `call_context` service used to name types and casts (by default it is the C type namer)
	fun build_ccall(recv_mtype: MClassType, from_mmodule: MModule, suffix: nullable String, length: SignatureLength, call_context: CallContext, param_suffix: nullable String): String
	do
		return build_ccall_intern(recv_mtype, from_mmodule, suffix, length, call_context, param_suffix, true)
	end

	fun build_ccall_from_c(recv_mtype: MClassType, from_mmodule: MModule, suffix: nullable String, length: SignatureLength, call_context: CallContext, param_suffix: nullable String): String
	do
		return build_ccall_intern(recv_mtype, from_mmodule, suffix, length, call_context, param_suffix, false)
	end

	private fun build_ccall_intern(recv_mtype: MClassType, from_mmodule: MModule, suffix: nullable String, length: SignatureLength, call_context: CallContext, param_suffix: nullable String, to_c: Bool): String
	do
		if param_suffix == null then param_suffix = ""

		var signature = self.intro.msignature
		assert signature != null

		var return_mtype = null
		if self.is_init then
			return_mtype = recv_mtype
		else if signature.return_mtype != null then
			return_mtype = signature.return_mtype
		end

		var cname = build_cname(recv_mtype, from_mmodule, suffix, length, call_context)

		var cparams = new List[String]
		if not self.is_init then if to_c then
			cparams.add(call_context.cast_to(recv_mtype, "recv{param_suffix}"))
		else
			cparams.add(call_context.cast_from(recv_mtype, "recv{param_suffix}"))
		end

		for p in signature.mparameters do
			if to_c then
				cparams.add(call_context.cast_to(p.mtype, "{p.name}{param_suffix}"))
			else
				cparams.add(call_context.cast_from(p.mtype, "{p.name}{param_suffix}"))
			end
		end

		if return_mtype != null then
			if to_c then
				return "return {call_context.cast_from(return_mtype, "{cname}( {cparams.join(", ")} )")};"
			else
				return "return {call_context.cast_to(return_mtype, "{cname}( {cparams.join(", ")} )")};"
			end
		else
			return "{cname}( {cparams.join(", ")} );"
		end
	end
end

class CallContext
	fun name_mtype(mtype: MType): String do return mtype.cname_blind
	fun cast_from(mtype: MType, name: String): String do return name
	fun cast_to(mtype: MType, name: String): String do return name
end

redef class Object
	protected fun internal_call_context: CallContext do return new CallContext

	protected fun long_signature: SignatureLength do return once new SignatureLength(true)
	protected fun short_signature: SignatureLength do return once new SignatureLength(false)
end

class SignatureLength
	private var long: Bool
	private init(long: Bool) do self.long = long
end
