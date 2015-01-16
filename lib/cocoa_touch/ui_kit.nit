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

# TODO
# The Cocoa API is the development layer of OS X
#
# This module is only compatible with OS X.
#
# This wrapper of the Cocoa API regroups the Foundation Kit and the
# Application Kit.
module ui_kit is c_linker_option "-framework UIKit"

import ios
