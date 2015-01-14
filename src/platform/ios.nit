# This file is part of NIT ( http://www.nitlanguage.org )
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

# Compile programs for iOS
module ios

import platform
import compiler::abstract_compiler

redef class ToolContext
	redef fun platform_from_name(name)
	do
		if name == "ios" then return new IOSPlatform
		return super
	end
end

class IOSPlatform
	super Platform

	redef fun supports_libunwind do return false
	redef fun supports_libgc do return false
	redef fun toolchain(toolcontext) do return new IOSToolchain(toolcontext)
end

class IOSToolchain
	super MakefileToolchain

	redef fun makefile_name(mainmodule) do return "{mainmodule.name}.ios.mk"

	#redef fun default_outname(mainmodule) do return "{super}.js"

	redef fun write_makefile(compiler, compile_dir, cfiles)
	do
		super

		var ios_version = "8.1"

		var cflags = "-Wno-unused-value -Wno-switch -Qunused-arguments " +
			"-isysroot `xcrun -sdk iphonesimulator8.1 -show-sdk-path`"

		var ldflags = "-isysroot `xcrun -sdk iphonesimulator8.1 -show-sdk-path` " +
			"-mios-simulator-version-min={ios_version}"
		# TODO add frameworks to ldflags?

		var release = toolcontext.opt_release.value
		if not release then
			cflags = cflags + " -g"
		end

		var make_flags = self.toolcontext.opt_make_flags.value or else ""
		make_flags += "CC=clang CXX=clang CFLAGS='{cflags}' LDFLAGS='{ldflags}'"
		self.toolcontext.opt_make_flags.value = make_flags
	end
end
